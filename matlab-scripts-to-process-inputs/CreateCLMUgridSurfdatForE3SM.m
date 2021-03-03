% ======================================================================= %
% Creates a structured surface-data netCDF file of ELM for E3Sm.
%
% # INPUTS #
%      in
%      clm_gridded_surfdata_filename = Gridded ELM surface data file
%      out_netcdf_dir = Directory where ELM surface dataset will be saved
%      clm_usrdat_name = User defined name for ELM dataset
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 09/25/2020
% 02/24/2021: add three parameters for sensitivitiy analysis of runoff
%             timing. (Donghui Xu)
% ======================================================================= %
function fname_out = CreateCLMUgridSurfdatForE3SM(  ...
                    in,                             ...
                    clm_gridded_surfdata_filename,  ...
                    out_netcdf_dir, clm_usrdat_name,...
                    fdrain,max_drain,ice_imped,snoalb_factor,fover)

if nargin == 4
    fdrain = [];
    write_fdrain = 0;
end
if nargin == 5
    max_drain = [];
    write_max_drain = 0;
end
if nargin == 6
    ice_imped = [];
    write_ice_imped = 0;
end
if nargin == 7
    snoalb_factor = [];
    write_snoalb_factor = 0;
end
if nargin == 8
    fover = [];
    write_fover = 0;
end
if ~isempty(fdrain)
    write_fdrain = 1;
end
if ~isempty(max_drain)
    write_max_drain = 1;
end
if ~isempty(ice_imped)
    write_ice_imped = 1;
end
if ~isempty(snoalb_factor)
    write_snoalb_factor = 1;
end
if ~isempty(fover)
    write_fover = 1;
end

% Default dimension is lon * lat
latixy = ncread(clm_gridded_surfdata_filename,'LATIXY');
longxy = ncread(clm_gridded_surfdata_filename,'LONGXY');
long_region = longxy(in);
lati_region = latixy(in);

fname_out = sprintf('%s/surfdata_%s_%s.nc',...
            out_netcdf_dir,clm_usrdat_name,datestr(now, 'cyymmdd'));
        
disp(['  surface_dataset: ' fname_out])

% Check if the file is available
if ~exist(clm_gridded_surfdata_filename, 'file')
    error(['File not found: ' mosart_gridded_surfdata_filename]);
end

% Check if the file is available
[s,~]=system(['ls ' clm_gridded_surfdata_filename]);

if (s ~= 0)
    error(['File not found: ' clm_gridded_surfdata_filename]);
end

ncid_inp = netcdf.open(clm_gridded_surfdata_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(clm_gridded_surfdata_filename);

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
                dimlen = length(long_region);
                %disp(['Out: Dimension name:' dimname])
                dimid(idim) = netcdf.defDim(ncid_out,dimname,dimlen);
            end
        case 'time'
            %disp(['Out: Dimension name:' dimname])
            dimid(idim) = netcdf.defDim(ncid_out,dimname,netcdf.getConstant('NC_UNLIMITED'));
        otherwise
            %disp(['Out: Dimension name:' dimname])
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
    %disp(['varname : ' varname ' ' num2str(dimids)])
    if(isempty(dimids)==0)
        if(dimids(1) == 0 && dimids(2) == 1)
            dimids_new =  [0 dimids(3:end)-1];
            dimids = dimids_new;
        else
            dimids = dimids - 1;
        end
    end
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimids);
    if strcmp(varname,'AREA')
        fdrain_dimids = dimids;
        fdrain_type = xtype;
    end
    varnames{ivar} = varname;
    %disp([num2str(ivar) ') varname : ' varname ' ' num2str(dimids)])
    
    for iatt = 1:natts
        attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
    
end
if write_fdrain
    ivar = nvars + 1;
    fdrainid = netcdf.defVar(ncid_out,'fdrain',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','subsurface drainage decay factor');
    netcdf.putAtt(ncid_out,ivar-1,'unites','m-1');
end
if write_max_drain
    ivar = ivar + 1;
    max_drain_id = netcdf.defVar(ncid_out,'max_drain',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','maximum bottom drainage rate');
    netcdf.putAtt(ncid_out,ivar-1,'unites','mm/s');
end
if write_ice_imped
    ivar = ivar + 1;
    ice_imped_id = netcdf.defVar(ncid_out,'ice_imped',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','parameter for ice impedance');
    netcdf.putAtt(ncid_out,ivar-1,'unites','m-1');
end
if write_snoalb_factor
    ivar = ivar + 1;
    ice_imped_id = netcdf.defVar(ncid_out,'snoalb_factor',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','parameter for snow albedo');
    netcdf.putAtt(ncid_out,ivar-1,'unites','[0-1]');
end
if write_fover
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'fover',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','decay factor for surface runoff');
    netcdf.putAtt(ncid_out,ivar-1,'unites','[0-1]');
end

varid = netcdf.getConstant('GLOBAL');

[~,user_name]=system('echo $USER');
netcdf.putAtt(ncid_out,varid,'Created_by' ,user_name(1:end-1));
netcdf.putAtt(ncid_out,varid,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
netcdf.endDef(ncid_out);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% Find the nearest neighbor index for (long_region,lati_xy) within global
% dataset
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

% Get Lat/Lon for global 2D grid.
for ivar = 1:length(varnames)
    if(strcmp(varnames{ivar},'LATIXY'))
        latixy = netcdf.getVar(ncid_inp,ivar-1);
    end
    if(strcmp(varnames{ivar},'LONGXY'))
        longxy = netcdf.getVar(ncid_inp,ivar-1);
    end
end

% read in global pft mask 1=valid 0=invalid
pftmask = ncread(clm_gridded_surfdata_filename,'PFTDATA_MASK');

% mark invalid gridcells as [lon, lat] [-9999, -9999]
latixy(pftmask==0)=-9999;
longxy(pftmask==0)=-9999;

% allocate memoery
ii_idx = zeros(size(long_region));
jj_idx = zeros(size(long_region));

% find the index
for ii=1:size(long_region,1)
    for jj=1:size(long_region,2)
        dist = (longxy - long_region(ii,jj)).^2 + (latixy - lati_region(ii,jj)).^2;
        [nearest_cell_i_idx, nearest_cell_j_idx] = find( dist == min(min(dist)));
        if (length(nearest_cell_i_idx) > 1)
            [i1,j1] = find(longxy == long_region(ii,jj) & latixy == lati_region(ii,jj));
            
            disp(['  WARNING: Site with (lat,lon) = (' sprintf('%f',lati_region(ii,jj)) ...
                sprintf(',%f',long_region(ii,jj)) ') has more than one cells ' ...
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
            netcdf.putVar(ncid_out,ivar-1,lati_region);
        case {'LONGXY'}
            netcdf.putVar(ncid_out,ivar-1,long_region);
        otherwise
            
            switch length(vardimids)
                case 0
                    netcdf.putVar(ncid_out,ivar-1,data);
                case 1
                    data = 0;
                    netcdf.putVar(ncid_out,ivar-1,0,length(data),data);
                case 2
                    if (min(vardimids) == 0)
                        data_2d = zeros(size(long_region));
                        for ii=1:size(long_region,1)
                            for jj=1:size(long_region,2)
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
                        nx = size(long_region,1);
                        ny = size(long_region,2);
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
                        nx = size(long_region,1);
                        ny = size(long_region,2);
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

if write_fdrain
    ivar = nvars + 1;
    netcdf.putVar(ncid_out,ivar-1,fdrain);
end
if write_max_drain
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,max_drain);
end
if write_ice_imped
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,ice_imped);
end
if write_snoalb_factor
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,snoalb_factor);
end
if write_fover
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,fover);
end
% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

end

