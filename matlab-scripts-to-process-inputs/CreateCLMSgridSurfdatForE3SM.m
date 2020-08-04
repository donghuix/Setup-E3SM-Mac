% ======================================================================= %
% Creates a structured surface-data netCDF file of ELM for E3Sm.
%
% # INPUTS #
%      xmin, xmax, ymin, ymax: coordinates of the rectangle corners to clip
%      clm_gridded_surfdata_filename = Gridded ELM surface data file
%      out_netcdf_dir = Directory where ELM surface dataset will be saved
%      clm_usrdat_name = User defined name for ELM dataset
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 06/11/2020
% ======================================================================= %
function fname_out = CreateCLMSgridSurfdatForE3SM(...
                    xmin, xmax, ymin, ymax,...
                    clm_gridded_surfdata_filename, ...
                    out_netcdf_dir, clm_usrdat_name)

% Default dimension is lon * lat
latixy = ncread(clm_gridded_surfdata_filename,'LATIXY');
longxy = ncread(clm_gridded_surfdata_filename,'LONGXY');
lon = longxy(:,1);
lat = latixy(1,:);

% Find the index corresponding the corners
ixmin  = find(abs(lon - xmin) == min(abs(lon-xmin)));
ixmax  = find(abs(lon - xmax) == min(abs(lon-xmax)));
iymin  = find(abs(lat - ymin) == min(abs(lat-ymin)));
iymax  = find(abs(lat - ymax) == min(abs(lat-ymax)));

latlen = iymax - iymin + 1;
lonlen = ixmax - ixmin + 1;
midstr = strcat(num2str(lonlen),'x',num2str('latlen'),'_grid');

fname_out = sprintf('%s/surfdata_%s_%s_%s.nc',...
            out_netcdf_dir,clm_usrdat_name,midstr,datestr(now, 'cyymmdd'));
        
disp(['  surface_dataset: ' fname_out])

% Check if the file is available
if ~exist(clm_gridded_surfdata_filename, 'file')
    error(['File not found: ' mosart_gridded_surfdata_filename]);
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

for idim = 1:ndims
    [dimname, dimlen] = netcdf.inqDim(ncid_inp,idim-1);
    %disp(['Inp: Dimension name:' dimname])
    
    switch dimname
        case {'lsmlon'}
            dimid(idim) = netcdf.defDim(ncid_out,dimname,lonlen);
        case {'lsmlat'}
            dimid(idim) = netcdf.defDim(ncid_out,dimname,latlen);
        case 'time'
            %disp(['Out: Dimension name:' dimname])
            dimid(idim) = netcdf.defDim(ncid_out,dimname,netcdf.getConstant('NC_UNLIMITED'));
        otherwise
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
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimids);
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
            
    switch length(vardimids)
        case 0
            netcdf.putVar(ncid_out,ivar-1,data);
        case 1
            netcdf.putVar(ncid_out,ivar-1,0,length(data),data);
        case 2
%             disp(data(ixmin:ixmax,iymin:iymax));
            netcdf.putVar(ncid_out,ivar-1,data(ixmin:ixmax,iymin:iymax));
        case 3
            netcdf.putVar(ncid_out,ivar-1,data(ixmin:ixmax,iymin:iymax,:));
        case 4
            netcdf.putVar(ncid_out,ivar-1,zeros(length(size(data(ixmin:ixmax,iymin:iymax,:,:))),1)',size(data(ixmin:ixmax,iymin:iymax,:,:)), data(ixmin:ixmax,iymin:iymax,:,:));
        otherwise
            disp('error')
    end
end


% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);


end

