
function generate_mosart_from_drt(drt,ftem,fmos,fdom,show_river)

% Input: 
% drt: DRT flow directions, distance, drainage area
% ftem: Template MOSART input file to intepolate on
% fmos: MOSART input file
% fdom: Domain file
% show_river: show_river = 1, show river net work. Default = 0
% show_attributes: show_attributes = 1, show attributes. Default = 0

    addpath('/Users/xudo627/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-to-process-inputs/');
    addpath('/Users/xudo627/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-for-mosart/');
    addpath('/Users/xudo627/donghui/mylib/m/');
    
    add_ele = 0;

    lon        = drt.longxy;
    lat        = drt.latixy;
    area       = drt.area;
    ID         = drt.ID;
    dnID       = drt.dnID;
    areaTotal2 = drt.facc;
    rlen       = drt.flen;% This is conceptual length. 
                                                 % TODO: replace with actual river legnth
    numc     = length(ID);
    % Read vertices
    lonv = drt.xv;
    latv = drt.yv;
    fdir = ones(numc,1);
    fdir(dnID == -9999) = 0;
    frac = ones(numc,1);
    
    if exist(drt.geometry_file,'file')
        load(drt.geometry_file);
    else
        [rwid,rdep,flood_2yr] = get_geometry(lon,lat,ID,dnID,area);
        save(drt.geometry_file,'rwid','rdep','flood_2yr');
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