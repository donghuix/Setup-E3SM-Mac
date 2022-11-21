
function generate_mosart_from_hexwatershed(fhex,ftem,fmos,fdom,show_river,show_attributes)

% Input: 
% fhex: HexWaterhsed output
% ftem: Template MOSART input file to intepolate on
% fmos: MOSART input file
% fdom: Domain file
% show_river: show_river = 1, show river net work. Default = 0
% show_attributes: show_attributes = 1, show attributes. Default = 0

    addpath('/Users/xudo627/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-to-process-inputs/');
    addpath('/Users/xudo627/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-for-mosart/');
    addpath('/Users/xudo627/donghui/mylib/m/');
    
    add_ele = 0;
    
    str = fileread(fhex);
    data = jsondecode(str);

    lon      = [data(:).dLongitude_center_degree]'; 
    lat      = [data(:).dLatitude_center_degree]';
    area     = [data(:).Area]';
    globalID = [data(:).lCellID]';
    globaldnID     = [data(:).lCellID_downslope]';
    Elevation      = [data(:).Elevation]';
    areaTotal2     = [data(:).DrainageArea]';
    dSlope_between = [data(:).dSlope_between]'; 
    rlen           = [data(:).dLength_flowline]';% This is conceptual length. 
                                                 % TODO: replace with actual river legnth
    numc     = length(globalID);
    % Read vertices
    lonv = NaN(8,numc);
    latv = NaN(8,numc);
    numv = NaN(length(globalID),1);
    for i = 1 : numc
        tmpx = [data(i).vVertex(:).dLongitude_degree];
        tmpy = [data(i).vVertex(:).dLatitude_degree];
        numv(i) = length(tmpx);
        lonv(1:length(tmpx),i) = tmpx;
        latv(1:length(tmpy),i) = tmpy;
    end

    % Convert ID
    ID = 1 : length(globalID);
    ID = ID';
    dnID = NaN(length(globalID),1);

    for i = 1 : length(ID)
        if globaldnID(i) == -9999
            dnID(i) = -9999;
        else
            ind = find(globalID == globaldnID(i));
            if isempty(ind)
                dnID(i) = -9999;
            else
                dnID(i) = ID(ind);
            end
        end
    end

    fdir = ones(length(globalID),1);
    fdir(dnID == -9999) = 0;
    frac = ones(length(globalID),1);
    
    if exist('channel_geometry.mat','file')
        load('channel_geometry.mat');
    else
        [rwid,rdep,flood_2yr] = get_geometry(lon,lat,ID,dnID,area);
        save('channel_geometry.mat','rwid','rdep','flood_2yr');
    end
    
%     if show_river
%         figure;
%         for i = 1 : length(ID)
%             if dnID(i) ~= -9999
%                 plot([lon(ID(i)) lon(dnID(i))],[lat(ID(i)) lat(dnID(i))],'b-','LineWidth',1.5);hold on;
%             else
%                 plot(lon(ID(i)),lat(ID(i)),'r*'); hold on;
%             end
%         end
%     end
    
    if show_attributes
        figure;
        subplot(1,3,1);
        for i = 4 : 8
            patch(lonv(1:i,numv == i),latv(1:i,numv == i),rlen(numv == i),'LineStyle','none'); colorbar; hold on;
        end
        set(gca,'ColorScale','log');
        title('River length [m]','FontSize',15,'FontWeight','bold');
        subplot(1,3,2);
        for i = 4 : 8
            patch(lonv(1:i,numv == i),latv(1:i,numv == i),rwid(numv == i),'LineStyle','none'); colorbar; hold on;
        end
        title('River width [m]','FontSize',15,'FontWeight','bold');
        subplot(1,3,3);
        for i = 4 : 8
            patch(lonv(1:i,numv == i),latv(1:i,numv == i),rdep(numv == i),'LineStyle','none'); colorbar; hold on;
        end
        title('River depth [m]','FontSize',15,'FontWeight','bold');
    end

    % Prepare MOSART inputfile by creating the netcdf file
    disp(['  MOSART_dataset: ' fmos]);
    ncid_inp = netcdf.open(ftem,'NC_NOWRITE');
    ncid_out = netcdf.create(fmos,'NC_CLOBBER');

    info_inp = ncinfo(ftem);
    [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

    latixy = ncread(ftem,'latixy');
    longxy = ncread(ftem,'longxy');

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    %
    %                           Define dimensions
    %
    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    dimid(1) = netcdf.defDim(ncid_out,'gridcell',length(lat));
    if add_ele == 1
        dimid(2) = netcdf.defDim(ncid_out,'nele',11);
    end

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    %
    %                           Define variables
    %
    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    found_ele = 0;
    for ivar = 1 : nvars
        [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
        if strcmp(varname,'ele')
            found_ele = 1;
            %dimid(2) = netcdf.defDim(ncid_out,'nele',11);
            varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,[dimid(1) dimid(2)]); 
        else
            varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1)); 
        end

        if strcmp(varname,'rdep')
            xtype2 = xtype;
        end
        varnames{ivar} = varname;
        for iatt = 1 : natts
            attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
            attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);

            netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
        end
    end
    if add_ele == 1 && found_ele == 0
        ivar = nvars + 1;
        fdrainid = netcdf.defVar(ncid_out,'ele',xtype2,[dimid(1) dimid(2)]);
        netcdf.putAtt(ncid_out,ivar-1,'long_name','elevation profile');
        netcdf.putAtt(ncid_out,ivar-1,'unites','m-1');
    end

    varid = netcdf.getConstant('GLOBAL');
    [~,user_name]=system('echo $USER');
    netcdf.putAtt(ncid_out,varid,'Created_by' ,user_name(1:end-1));
    netcdf.putAtt(ncid_out,varid,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
    netcdf.putAtt(ncid_out,varid,'Interpolate_from' ,ftem);
    netcdf.endDef(ncid_out);

    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    %
    %                           Copy variables
    %
    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    for ivar = 1:nvars
        [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
        tmp = netcdf.getVar(ncid_inp,ivar-1);
        if strcmp(varname,'lat') || strcmp(varname,'latixy')
            netcdf.putVar(ncid_out,ivar-1,lat);
        elseif strcmp(varname,'lon') || strcmp(varname,'longxy')
            netcdf.putVar(ncid_out,ivar-1,lon);
        elseif strcmp(varname,'rslp') || strcmp(varname,'tslp')
            netcdf.putVar(ncid_out,ivar-1,dSlope_between);
        elseif strcmp(varname,'ID')
            netcdf.putVar(ncid_out,ivar-1,ID);
        elseif strcmp(varname,'dnID')
            netcdf.putVar(ncid_out,ivar-1,dnID);
        elseif strcmp(varname,'frac')
            netcdf.putVar(ncid_out,ivar-1,frac);
        elseif strcmp(varname,'fdir')
            netcdf.putVar(ncid_out,ivar-1,fdir);
        elseif strcmp(varname,'rdep')
            netcdf.putVar(ncid_out,ivar-1,rdep);
        elseif strcmp(varname,'rwid')
            netcdf.putVar(ncid_out,ivar-1,rwid);
        elseif strcmp(varname,'rwid0')
            netcdf.putVar(ncid_out,ivar-1,rwid.*5);
        elseif strcmp(varname,'areaTotal') || strcmp(varname,'areaTotal2')
            netcdf.putVar(ncid_out,ivar-1,areaTotal2);
        elseif strcmp(varname,'area')
            netcdf.putVar(ncid_out,ivar-1,area);
        elseif strcmp(varname,'rlen')
            netcdf.putVar(ncid_out,ivar-1,rlen);
        elseif strcmp(varname,'ele')
            netcdf.putVar(ncid_out,ivar-1,ele);
        else
            tmpv = griddata(longxy,latixy,tmp,lon,lat,'nearest');
            tmpv(tmpv < -9000) = NaN;
            tmpv = fillmissing(tmpv,'nearest');
            netcdf.putVar(ncid_out,ivar-1,tmpv);
        end
    end
    if add_ele == 1 && found_ele == 0
        ivar = nvars + 1;
        netcdf.putVar(ncid_out,ivar-1,ele);
    end

    % close files
    netcdf.close(ncid_inp);
    netcdf.close(ncid_out);
    
    if show_river
        figure;
        show_river_network(fmos,0.1);
    end

    mask = zeros(length(frac),1);
    mask(frac > 0) = 1;                  
    area2 = generate_lnd_domain(lon,lat,lonv,latv,frac,mask,area,fdom);
end