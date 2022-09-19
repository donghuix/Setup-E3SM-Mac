function fname_out = generate_wm_1d(lon,lat,wmfile,out_netcdf_dir, wm_usrdat_name)
%
% lon, lat: domain grid cells coordinate
% wmfile: template water management parameter file 
%
    ncell = length(lon);

    k = boundary(lon,lat,1);
    xb = lon(k); yb = lat(k);
    lon_wm = ncread(wmfile,'lon');
    lat_wm = ncread(wmfile,'lat');
    lon_wm(lon_wm < 0) = lon_wm(lon_wm < 0) + 360;
    [x_wm, y_wm] = meshgrid(lon_wm,lat_wm);
    x_wm = x_wm';
    y_wm = y_wm';
    unitID_1D = ncread(wmfile,'unitID_1D');
    unit_ID = ncread(wmfile,'unit_ID');
    DamInd_2d = ncread(wmfile,'DamInd_2d');
    gridID_from_Dam = ncread(wmfile,'gridID_from_Dam');
    Dams = ncread(wmfile,'Dams');
    [Dams_in,on] = inpolygon(x_wm(unitID_1D),y_wm(unitID_1D),xb,yb);
    Dams_in(on) = 0;
    Dams_in(1022) = 0; % Very large dam
    ndams = sum(Dams_in);
    ndepend = 881;
    for i = 1 : ncell
        ind_region(i) = find(x_wm == lon(i) & y_wm == lat(i));
    end
    
    ID_region = 1 : ncell; ID_region = ID_region';
    Dams_region = 1 : ndams; Dams_region = Dams_region';
%     ID_1d = unit_ID(ind_region);
    Dams_1d = Dams(Dams_in);
    unit_ID_region = unit_ID(ind_region);
    gridID_from_Dam_region = gridID_from_Dam(Dams_in,:);
    DamInd_region  = DamInd_2d(ind_region);
    
    fname_out = sprintf('%s/reservoir_%s_%s.nc',...
            out_netcdf_dir,wm_usrdat_name,datestr(now, 'cyymmdd'));
        
    disp(['  surface_dataset: ' fname_out]);
    % Check if the file is available
    if ~exist(wmfile, 'file')
        error(['File not found: ' mosart_gridded_surfdata_filename]);
    end
    
    ncid_inp = netcdf.open(wmfile,'NC_NOWRITE');
    ncid_out = netcdf.create(fname_out,'NC_CLOBBER');
    
    info_inp = ncinfo(wmfile);
    [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);
    
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    dimid(1) = netcdf.defDim(ncid_out,'gridcell',ncell);
    dimid(2) = netcdf.defDim(ncid_out,'DependentGrids',ndepend);
    dimid(3) = netcdf.defDim(ncid_out,'Dams',ndams);
    dimid(4) = netcdf.defDim(ncid_out,'Month',12);
    
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    if length(dimids) == 2
        if dimids(1) == 1 && dimids(2) == 0
            varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1));
        elseif dimids(1) == 3 && dimids(2) == 2
            dimids = dimids - 1;
            varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimids);
        elseif dimids(1) == 3 && dimids(2) == 4
            dimids = dimids - 1;
            varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimids);
        end
    elseif length(dimids) == 1
        if dimids == 0 || dimids == 1
            varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1));
        else
            varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimids-1);
        end
    end
    varnames{ivar} = varname;
    for iatt = 1:natts
        attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
end
    
varid = netcdf.getConstant('GLOBAL');

[~,user_name]=system('echo $USER');
netcdf.putAtt(ncid_out,varid,'Created_by' ,user_name(1:end-1));
netcdf.putAtt(ncid_out,varid,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
netcdf.endDef(ncid_out);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Copy variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for ivar = 1:nvars
    
    %disp(varnames{ivar})
    [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
    data = netcdf.getVar(ncid_inp,ivar-1);
    
    switch varname
        case {'unit_ID'}
            netcdf.putVar(ncid_out,ivar-1,ID_region);
        case {'lat'}
            netcdf.putVar(ncid_out,ivar-1,lat);
        case {'lon'}
            netcdf.putVar(ncid_out,ivar-1,lon);
        case {'Qmon'}
            netcdf.putVar(ncid_out,ivar-1,data(Dams_in,:));
        case {'demand','distance','gridID_from_Dam_sorted'}
            netcdf.putVar(ncid_out,ivar-1,data(Dams_in,:));
        case {'DependentGrids','Month'}
            netcdf.putVar(ncid_out,ivar-1,data);
        case {'unitID_1D'}
            unitID_1D_tmp = unitID_1D(Dams_in);
            for i = 1 : ndams
                unitID_1D_region(i) = find(unit_ID_region == unitID_1D_tmp(i));
            end
            netcdf.putVar(ncid_out,ivar-1,unitID_1D_region);
        case {'Dams'}
            netcdf.putVar(ncid_out,ivar-1,Dams_region);
        case {'gridID_from_Dam'}
            for i = 1 : ndams
                for j = 1 : ndepend
                    if ~isnan(gridID_from_Dam_region(i,j))
                        k = find(unit_ID_region == gridID_from_Dam_region(i,j));
                        if inpolygon(lon(k),lat(k),xb,yb)
                            gridID_from_Dam_region(i,j) = k;
                        else
                            gridID_from_Dam_region(i,j) = NaN;
                        end
                    end
                end
            end
            gridID_from_Dam_region = sort(gridID_from_Dam_region,2);
            netcdf.putVar(ncid_out,ivar-1,gridID_from_Dam_region);
        case {'DamInd_2d'}
            for i = 1 : ncell
                if isnan(DamInd_region(i))
                    DamInd_2d_region(i) = NaN;
                else
                    k = find(Dams_1d == DamInd_region(i));
                    if isempty(k)
                        DamInd_2d_region(i) = NaN;
                    else
                        DamInd_2d_region(i) = k;
                    end
                end
            end
            netcdf.putVar(ncid_out,ivar-1,DamInd_2d_region);
        case {'DamGrndID'}
            netcdf.putVar(ncid_out,ivar-1,data(Dams_in));
        otherwise 
            data_region = data(ind_region);
            netcdf.putVar(ncid_out,ivar-1,data_region);
    end
    
end
    netcdf.close(ncid_inp);
    netcdf.close(ncid_out);
end
