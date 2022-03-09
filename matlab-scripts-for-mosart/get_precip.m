function [precipin, yr, mo, xc, yc, xv, yv] = get_precip(S,name)
    if strcmp(name,'TRMM')
        [precipin, yr, mo, xc, yc, xv, yv] = get_TRMM_precipitation(S);
    elseif strcmp(name,'GPCC')
        [precipin, yr, mo, xc, yc, xv, yv] = get_GPCC_precipitation(S);
    elseif strcmp(name,'MSWEP')
        [precipin, yr, mo, xc, yc, xv, yv] = get_MSWEP_precipitation(S);
    elseif strcmp(name,'UDEL')
        [precipin, yr, mo, xc, yc, xv, yv] = get_UDEL_precipitation(S);
    elseif strcmp(name,'MERRA')
        [precipin, yr, mo, xc, yc, xv, yv] = get_MERRA_precipitation(S);
    elseif strcmp(name,'PRECL')
        [precipin, yr, mo, xc, yc, xv, yv] = get_PRECL_precipitation(S);
    end
end

function [MSWEPin, yr, mo, xc, yc, xv, yv] = get_MSWEP_precipitation(S)
    
    datadir = '/Volumes/LaCie/DATA/Precipitation/MSWEP/';
    days_of_month = [31;28;31;30;31;30;31;31;30;31;30;31];
    yr_sr = 1980;
    yr_ed = 2019;
    
    for i = yr_sr : yr_ed
        if ~exist([datadir num2str(i) '.mat'],'file')
            disp(['Processing for ' num2str(i) '...']);
            MSWEP = NaN(3600,1800,12);
            k = 1;
            for j = 1 : 12
                if j < 10
                    filename = [datadir num2str(i) '0' num2str(j) '.nc'];
                else
                    filename = [datadir num2str(i) num2str(j) '.nc'];
                end
                disp(filename);
                if k == 1
                    lon = ncread(filename,'lon');
                    lat = ncread(filename,'lat');
                    [lon,lat] = meshgrid(lon,lat);
                    lon = lon';
                    lat = lat';
                end
                precipitation = ncread(filename,'precipitation');
                MSWEP(:,:,k) = precipitation./days_of_month(j)./24; % [mm/month] -> [mm/hour]
                k = k + 1;
            end
            save([datadir num2str(i) '.mat'],'MSWEP','lon','lat');
        end
    end
    
    load([datadir num2str(yr_sr) '.mat'],'lon','lat');
    
    in = inpolygon(lon,lat,S.X,S.Y);
    dx = 0.1;
    dy = 0.1;
    l = (yr_ed - yr_sr + 1) * 12;
    k = 1;
    for i = yr_sr : yr_ed
        for j = 1 : 12
            tmon(k,1) = datenum(i,j,1,1,1,1);
            k = k + 1;
        end
    end
    [yr,mo] = datevec(tmon);
    xv = NaN(4,sum(in(:)));
    yv = NaN(4,sum(in(:)));
    MSWEPin = NaN(sum(in(:)),l);
    k = 1;
    for i = yr_sr : yr_ed
        load([datadir num2str(i) '.mat'],'MSWEP');
        for j = 1 : 12
            tmp = MSWEP(:,:,j);
            MSWEPin(:,k) = tmp(in); % [mm/month] -> [mm/hour]
            k = k + 1;
        end
    end
    xc = lon(in);
    yc = lat(in);
    
    xv(1,:) = xc - dx/2; xv(2,:) = xc + dx/2; xv(3,:) = xc + dx/2; xv(4,:) = xc - dx/2;
    yv(1,:) = yc - dy/2; yv(2,:) = yc - dy/2; yv(3,:) = yc + dy/2; yv(4,:) = yc + dy/2;
    
end

function [UDELin, yr, mo, xc, yc, xv, yv] = get_UDEL_precipitation(S)
    
    datadir = '/Volumes/LaCie/DATA/Precipitation/UDEL/';
    days_of_month = [31;28;31;30;31;30;31;31;30;31;30;31];
    yr_sr = 1970;
    yr_ed = 2017;
    
    if exist([datadir 'UDEL.mat'],'file')
        load([datadir 'UDEL.mat']);
    else
        for i = yr_sr : yr_ed
            filename = [datadir 'precip.' num2str(i)];
            disp(filename);
            M = dlmread(filename);
            if i == yr_sr
                lon = M(:,1);
                lat = M(:,2);
                UDEL = M(:,3:14);
            else
                UDEL = cat(2,UDEL,M(:,3:14));
            end
        end
        save([datadir 'UDEL.mat'],'UDEL','lon','lat');
    end
    
    in = inpolygon(lon,lat,S.X,S.Y);
    dx = 0.5;
    dy = 0.5;
    l = (yr_ed - yr_sr + 1) * 12;
    k = 1;
    for i = yr_sr : yr_ed
        for j = 1 : 12
            tmon(k,1) = datenum(i,j,1,1,1,1);
            k = k + 1;
        end
    end
    [yr,mo] = datevec(tmon);
    xv = NaN(4,sum(in(:)));
    yv = NaN(4,sum(in(:)));
    UDELin = NaN(sum(in(:)),l);
    k = 1;
    for i = yr_sr : yr_ed
        for j = 1 : 12
            tmp = UDEL(:,k);
            UDELin(:,k) = tmp(in)./days_of_month(mo(k))./24; % [mm/month] -> [mm/hour]
            k = k + 1;
        end
    end
    xc = lon(in);
    yc = lat(in);
    
    xv(1,:) = xc - dx/2; xv(2,:) = xc + dx/2; xv(3,:) = xc + dx/2; xv(4,:) = xc - dx/2;
    yv(1,:) = yc - dy/2; yv(2,:) = yc - dy/2; yv(3,:) = yc + dy/2; yv(4,:) = yc + dy/2;
    
end

function [MERRAin, yr, mo, xc, yc, xv, yv] = get_MERRA_precipitation(S)
    
    datadir = '/Volumes/LaCie/DATA/Precipitation/MERRA-land/';
    days_of_month = [31;28;31;30;31;30;31;31;30;31;30;31];
    yr_sr = 1980;
    yr_ed = 2015;
    nmon  = (yr_ed - yr_sr + 1) * 12;
    
    if exist([datadir 'MERRA.mat'],'file')
        load([datadir 'MERRA.mat']);
    else
        MERRA = NaN(540,361,nmon);
        k = 1;
        for i = yr_sr : yr_ed
            for j = 1 : 12
                if i < 1993
                    tag = '100';
                elseif i < 2001
                    tag = '200';
                else
                    tag = '300';
                end
                if j < 10
                filename = [datadir 'MERRA' tag '.prod.simul.tavgM_2d_mld_Nx.' num2str(i) '0' num2str(j) '.hdf.nc4'];
                else
                filename = [datadir 'MERRA' tag '.prod.simul.tavgM_2d_mld_Nx.' num2str(i) num2str(j) '.hdf.nc4'];
                end
                disp(filename);
                if k == 1
                    XDim = ncread(filename,'XDim');
                    YDim = ncread(filename,'YDim');
                    [lon,lat] = meshgrid(XDim,YDim);
                    lon = lon';lon = lon + 1/3;
                    lat = lat';
                end
                PRECTOT = ncread(filename,'PRECTOT').*86400.*days_of_month(j);
                MERRA(:,:,k) = PRECTOT;
                k = k + 1;
            end
        end
        save([datadir 'MERRA.mat'],'MERRA','lon','lat');
    end
    
    in = inpolygon(lon,lat,S.X,S.Y);
    dx = 0.2/3;
    dy = 0.5;

    k = 1;
    for i = yr_sr : yr_ed
        for j = 1 : 12
            tmon(k,1) = datenum(i,j,1,1,1,1);
            k = k + 1;
        end
    end
    [yr,mo] = datevec(tmon);
    xv = NaN(4,sum(in(:)));
    yv = NaN(4,sum(in(:)));
    MERRAin = NaN(sum(in(:)),nmon);
    k = 1;
    for i = yr_sr : yr_ed
        for j = 1 : 12
            tmp = MERRA(:,:,k);
            MERRAin(:,k) = tmp(in)./days_of_month(mo(k))./24; % [mm/month] -> [mm/hour]
            k = k + 1;
        end
    end
    xc = lon(in);
    yc = lat(in);
    
    xv(1,:) = xc - dx/2; xv(2,:) = xc + dx/2; xv(3,:) = xc + dx/2; xv(4,:) = xc - dx/2;
    yv(1,:) = yc - dy/2; yv(2,:) = yc - dy/2; yv(3,:) = yc + dy/2; yv(4,:) = yc + dy/2;
    
end

function [PRECLin, yr, mo, xc, yc, xv, yv] = get_PRECL_precipitation(S)
    
    days_of_month = [31;28;31;30;31;30;31;31;30;31;30;31];
    datadir = '/Volumes/LaCie/DATA/Precipitation/PRECL/';
    lon = ncread([datadir 'precip.mon.mean.0.5x0.5.nc'],'lon');
    lat = ncread([datadir 'precip.mon.mean.0.5x0.5.nc'],'lat');
    precip = ncread([datadir 'precip.mon.mean.0.5x0.5.nc'],'precip');
    [lon,lat] = meshgrid(lon,lat);
    lon = lon'; lon(lon > 180) = lon(lon > 180) - 360;
    lat = lat';
    
    in = inpolygon(lon,lat,S.X,S.Y);
    
    dx = 0.5;
    dy = 0.5;
    
    yr_sr = 1948;
    yr_ed = 2011;
    
    l = size(precip,3);
    
    k = 1;
    for i = yr_sr : yr_ed
        for j = 1 : 12
            tmon(k,1) = datenum(i,j,1,1,1,1);
            k = k + 1;
        end
    end
    [yr,mo] = datevec(tmon);
    
    xv = NaN(4,sum(in(:)));
    yv = NaN(4,sum(in(:)));
    PRECLin = NaN(sum(in(:)),l);
    
    for i = 1 : l
        tmp = precip(:,:,i);
        PRECLin(:,i) = tmp(in)./24; % [mm/day] -> [mm/hour]
    end
    xc = lon(in);
    yc = lat(in);
    
    xv(1,:) = xc - dx/2; xv(2,:) = xc + dx/2; xv(3,:) = xc + dx/2; xv(4,:) = xc - dx/2;
    yv(1,:) = yc - dy/2; yv(2,:) = yc - dy/2; yv(3,:) = yc + dy/2; yv(4,:) = yc + dy/2;  
end

function [GPCCin, yr, mo, xc, yc, xv, yv] = get_GPCC_precipitation(S)
    
    days_of_month = [31;28;31;30;31;30;31;31;30;31;30;31];
    datadir = '/Volumes/LaCie/DATA/Precipitation/GPCC/';
    lon = ncread([datadir 'precip.mon.total.v2018.nc'],'lon');
    lat = ncread([datadir 'precip.mon.total.v2018.nc'],'lat');
    precip = ncread([datadir 'precip.mon.total.v2018.nc'],'precip');
    [lon,lat] = meshgrid(lon,lat);
    lon = lon'; lon(lon > 180) = lon(lon > 180) - 360;
    lat = lat';
    
    in = inpolygon(lon,lat,S.X,S.Y);
    
    dx = 0.5;
    dy = 0.5;
    
    yr_sr = 1891;
    yr_ed = 2016;
    
    l = size(precip,3);
    
    k = 1;
    for i = yr_sr : yr_ed
        for j = 1 : 12
            tmon(k,1) = datenum(i,j,1,1,1,1);
            k = k + 1;
        end
    end
    [yr,mo] = datevec(tmon);
    
    xv = NaN(4,sum(in(:)));
    yv = NaN(4,sum(in(:)));
    GPCCin = NaN(sum(in(:)),l);
    
    for i = 1 : l
        tmp = precip(:,:,i);
        GPCCin(:,i) = tmp(in)./days_of_month(mo(i))./24; % [mm/month] -> [mm/hour]
    end
    xc = lon(in);
    yc = lat(in);
    
    xv(1,:) = xc - dx/2; xv(2,:) = xc + dx/2; xv(3,:) = xc + dx/2; xv(4,:) = xc - dx/2;
    yv(1,:) = yc - dy/2; yv(2,:) = yc - dy/2; yv(3,:) = yc + dy/2; yv(4,:) = yc + dy/2;  
end

function [TRMMin, yr, mo, xc, yc, xv, yv] = get_TRMM_precipitation(S)

    load('/Users/xudo627/DATA/TRMM/TRMMmon.mat');
    in = inpolygon(lon,lat,S.X,S.Y);
    
    dx = 1/4;
    dy = 1/4;
    
    [m,n,l] = size(TRMMmon);
    
    xv = NaN(4,sum(in(:)));
    yv = NaN(4,sum(in(:)));
    TRMMin = NaN(sum(in(:)),l);
    
    for i = 1 : l
        tmp = TRMMmon(:,:,i);
        TRMMin(:,i) = tmp(in);
    end
    xc = lon(in);
    yc = lat(in);
    
    xv(1,:) = xc - dx/2; xv(2,:) = xc + dx/2; xv(3,:) = xc + dx/2; xv(4,:) = xc - dx/2;
    yv(1,:) = yc - dy/2; yv(2,:) = yc - dy/2; yv(3,:) = yc + dy/2; yv(4,:) = yc + dy/2;
    
    k = 1;
    for i = 1998 : 2019
        for j = 1 : 12
            tmon(k,1) = datenum(i,j,1,1,1,1);
            k = k + 1;
        end
    end
    [yr,mo] = datevec(tmon);
    
end