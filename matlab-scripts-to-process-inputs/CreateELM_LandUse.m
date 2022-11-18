% ======================================================================= %
% Creates a unstructured landuse time series netCDF file of ELM for E3Sm.
%
% # INPUTS #
%      lon_region, lat_region
%      fin = Gridded ELM landuse time sereis
%      out_netcdf_dir = Directory where ELM land use time series will be saved
%      usrdat_name = User defined name for ELM dataset
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 11/18/2022
% ======================================================================= %
function fname_out = CreateELM_LandUse( lon_region, lat_region,        ...
                                        fname_in, out_netcdf_dir, usrdat_name )

% Default dimension is lon * lat
latixy = ncread(fname_in,'LATIXY');
longxy = ncread(fname_in,'LONGXY');

% landuse.timeseries_NLDAS_hist_50pfts_simyr1850-2015_erosion_c191004.nc
fname_out = sprintf('%s/landuse.timeseries_%s_%s.nc',...
            out_netcdf_dir,usrdat_name,datestr(now, 'cyymmdd'));
        
disp(['  landuse.timesereis: ' fname_out]);

% Check if the file is available
if ~exist(fname_in, 'file')
    error(['File not found: ' fname_in]);
end

ncid_inp = netcdf.open(fname_in,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(fname_in);

[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1:ndims) = -1;
lonlat_found = 0;

for idim = 1:ndims
    [dimname, dimlen] = netcdf.inqDim(ncid_inp,idim-1);
    %disp(['Inp: Dimension name:' dimname])
    
    switch dimname
        case {'lsmlon','lsmlat'}
            if (strcmp(dimname,'lsmlat'))
                lat_dimid = idim;
            else
                lon_dimid = idim;
            end
            
            if (lonlat_found == 0)
                lonlat_found = 1;
                dimname = 'gridcell';
                dimlen = length(lon_region);
                disp(['Out: Dimension name:' dimname])
                dimid(idim) = netcdf.defDim(ncid_out,dimname,dimlen);
            end
        case 'time'
            disp(['Out: Dimension name:' dimname])
            dimid(idim) = netcdf.defDim(ncid_out,dimname,netcdf.getConstant('NC_UNLIMITED'));
        otherwise
            disp(['Out: Dimension name:' dimname])
            for ii=1:length(info_inp.Dimensions)
                if (strcmp(info_inp.Dimensions(ii).Name,dimname) == 1)
                    [dimname, dimlen] = netcdf.inqDim(ncid_inp,ii-1);
                end
            end
            dimid(idim) = netcdf.defDim(ncid_out,dimname,dimlen);
    end
end

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for ivar = 1:nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    disp(['varname : ' varname ' ' num2str(dimids)])
    if(isempty(dimids)==0)
        if (dimids(1) == 1 && dimids(2) == 0)
            dimids_new =  [0 dimids(3:end)-1];
            dimids = dimids_new;
        elseif (dimids(1) == 0 && dimids(2) == 1)
            dimids_new =  [0 dimids(3:end)-1];
            dimids = dimids_new;
        else
            dimids = dimids - 1;
        end
    end
    disp(['varname : ' varname ' ' num2str(dimids)])
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimids);
    varnames{ivar} = varname;
    %disp([num2str(ivar) ') varname : ' varname ' ' num2str(dimids)])
    
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
netcdf.putAtt(ncid_out,varid,'Interpolate_from' , fname_in);
netcdf.endDef(ncid_out);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% Find the nearest neighbor index for (lon_region,lat_xy) within global
% dataset
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

% allocate memoery
ii_idx = zeros(size(lon_region));
jj_idx = zeros(size(lon_region));

% find the index
for ii=1:size(lon_region,1)
    for jj=1:size(lon_region,2)
        dist = (longxy - lon_region(ii,jj)).^2 + (latixy - lat_region(ii,jj)).^2;
        [nearest_cell_i_idx, nearest_cell_j_idx] = find( dist == min(min(dist)));
        if (length(nearest_cell_i_idx) > 1)
            [i1,j1] = find(longxy == lon_region(ii,jj) & latixy == lat_region(ii,jj));
            
            disp(['  WARNING: Site with (lat,lon) = (' sprintf('%f',lat_region(ii,jj)) ...
                sprintf(',%f',lon_region(ii,jj)) ') has more than one cells ' ...
                'that are equidistant.' char(10) ...
                '           Picking the first closest grid cell.']);
            for kk = 1:length(nearest_cell_i_idx)
                disp(sprintf('\t\tPossible grid cells: %f %f', ...
                    latixy(nearest_cell_i_idx(kk),nearest_cell_j_idx(kk)), ...
                    longxy(nearest_cell_i_idx(kk),nearest_cell_j_idx(kk))));
            end
        end
        ii_idx(ii,jj) = nearest_cell_i_idx(1);
        jj_idx(ii,jj) = nearest_cell_j_idx(1);
    end
end

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
        case {'LATIXY'}
            netcdf.putVar(ncid_out,ivar-1,lat_region);
        case {'LONGXY'}
            netcdf.putVar(ncid_out,ivar-1,lon_region);
        otherwise
            
            switch length(vardimids)
                case 0
                    netcdf.putVar(ncid_out,ivar-1,data);
                case 1
                    data = 0;
                    netcdf.putVar(ncid_out,ivar-1,0,length(data),data);
                case 2
                    if (min(vardimids) == 0)
                        data_2d = zeros(size(lon_region));
                        for ii=1:size(lon_region,1)
                            for jj=1:size(lon_region,2)
                                data_2d(ii,jj) = data(ii_idx(ii,jj),jj_idx(ii,jj));
                            end
                        end
                        
                        % (lon,lat) --> % (gridcell)
                        vardimids_new =  [0 vardimids(3:end)-1];
                        vardimids = vardimids_new;
                        dims = size(data_2d);
                        if (length(dims)>2)
                            dims_new = [dims(1)*dims(2) dims(3:end)];
                        else
                            dims_new = [dims(1)*dims(2) 1];
                        end
                        data_2d_new = reshape(data_2d,dims_new);
                        data_2d = data_2d_new;
                        
                        netcdf.putVar(ncid_out,ivar-1,data_2d);
                    else
                        netcdf.putVar(ncid_out,ivar-1,data);
                    end
                case 3
                    if (min(vardimids) == 0)
                        nx = size(lon_region,1);
                        ny = size(lon_region,2);
                        nz = size(data,3);
                        data_3d = zeros(nx,ny,nz);
                        for ii = 1:nx
                            for jj = 1:ny
                                for kk = 1:nz
                                    data_3d(ii,jj,kk) = data(ii_idx(ii,jj),jj_idx(ii,jj),kk);
                                end
                            end
                        end
                        
                        % (lon,lat,:) --> % (gridcell,:)
                        vardimids_new =  [0 vardimids(3:end)-1];
                        vardimids = vardimids_new;
                        dims = size(data_3d);
                        if (length(dims)>2)
                            dims_new = [dims(1)*dims(2) dims(3:end)];
                        else
                            dims_new = [dims(1)*dims(2) 1];
                        end
                        data_3d_new = reshape(data_3d,dims_new);
                        data_3d = data_3d_new;

                        netcdf.putVar(ncid_out,ivar-1,data_3d);
                    else
                        netcdf.putVar(ncid_out,ivar-1,data);
                    end
                case 4
                    if (min(vardimids) == 0)
                        nx = size(lon_region,1);
                        ny = size(lon_region,2);
                        nz = size(data,3);
                        na = size(data,4);
                        data_4d = zeros(nx,ny,nz,na);
                        for ii = 1:nx
                            for jj = 1:ny
                                for kk = 1:nz
                                    for ll = 1:na
                                        data_4d(ii,jj,kk,ll) = data(ii_idx(ii,jj),jj_idx(ii,jj),kk,ll);
                                    end
                                end
                            end
                        end
                        
                        % (lon,lat,:) --> % (gridcell,:)
                        vardimids_new =  [0 vardimids(3:end)-1];
                        vardimids = vardimids_new;
                        dims = size(data_4d);
                        if (length(dims)>2)
                            dims_new = [dims(1)*dims(2) dims(3:end)];
                        else
                            dims_new = [dims(1)*dims(2) 1];
                        end
                        data_4d_new = reshape(data_4d,dims_new);
                        data_4d = data_4d_new;
                        
                        netcdf.putVar(ncid_out,ivar-1,zeros(length(size(data_4d)),1)',size(data_4d),data_4d);
                    else
                        netcdf.putVar(ncid_out,ivar-1,data);
                    end
                otherwise
                    disp('error')
            end
    end
end

% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

end

