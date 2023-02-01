function [et_in,lon_in,lat_in,tmon_in] = get_GLEAM_ET(S,yr1,yr2,data_dir)
    
    if nargin == 3
        data_dir = '/Users/xudo627/projects/ELM_Runoff_Sensitivity/global/ILAMB/DATA/et/GLEAMv3.3a/et.nc';
        varname = 'et';
    end
    lon = ncread(data_dir,'lon');
    lat = ncread(data_dir,'lat');
    [lon,lat] = meshgrid(lon,lat); lon = lon'; lat = lat';
    et  = ncread(data_dir,varname);
    yr_start = 1980;
    yr_end   = 2018;
    
    k = 1;
    for i = yr_start : yr_end
        for j = 1 : 12
            tmon(k,1) = datenum(i,j,1,1,1,1);
            k = k + 1;
        end
    end
    [yrs,mos] = datevec(tmon);
    
    in = inpolygon(lon,lat,S.X,S.Y);
    [~,~,l] = size(et);
    
    assert(l == (yr_end-yr_start+1)*12);
    
    if yr1 < yr_start || yr2 > yr_end
        disp(['Year ' num2str(yr1) ' is not available..']);
        stop(['Please pick period between ' num2str(yr_start) ' and ' num2str(yr_end)]);
    end
    
    ind = find(yrs >= yr1 & yrs <= yr2);
    
    et_in = NaN(sum(in(:)),length(ind));
    
    for i = 1 : length(ind)
        tmp = et(:,:,ind(i));
        et_in(:,i) = tmp(in);
    end
    
    lon_in = lon(in);
    lat_in = lat(in);
    
    tmon_in = tmon(ind);

end

