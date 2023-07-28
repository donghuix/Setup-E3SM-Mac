% ======================================================================= %
% Creates a structured input netCDF file of MOSART for E3SM.
%
% # INPUTS #
% xmin, xmax, ymin, ymax: coordinates of the rectangle corners to clip
% mosart_gridded_surfdata_filename: Global gridded MOSART input data file
% out_netcdf_dir: Directory where MOSART input dataset will be saved
% mosart_usrdat_name: User defined name for MOSART dataset
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 06/11/2020
% ======================================================================= %
function fname_out = CreateMOSARTSgrid(xmin, xmax, ymin, ymax,           ...
                                       mosart_gridded_surfdata_filename, ...
                                       out_netcdf_dir, mosart_usrdat_name)

% Default dimension is lon * lat
ID     = ncread(mosart_gridded_surfdata_filename,'ID');
dnID   = ncread(mosart_gridded_surfdata_filename,'dnID');
lat    = ncread(mosart_gridded_surfdata_filename,'lat');
lon    = ncread(mosart_gridded_surfdata_filename,'lon');

% Find the index corresponding the corners
ixmin  = find(abs(lon - xmin) == min(abs(lon-xmin)));
ixmax  = find(abs(lon - xmax) == min(abs(lon-xmax)));
iymin  = find(abs(lat - ymin) == min(abs(lat-ymin)));
iymax  = find(abs(lat - ymax) == min(abs(lat-ymax)));
latlen = iymax - iymin + 1;
lonlen = ixmax - ixmin + 1;
midstr = strcat(num2str(lonlen),'x',num2str('latlen'),'_grid');

fname_out = sprintf('%s/MOSART_%s_%s_%s.nc',...
            out_netcdf_dir,mosart_usrdat_name,midstr,datestr(now, 'cyymmdd'));
        
disp(['  MOSART_dataset: ' fname_out])

% Check if the file is available
if ~exist(mosart_gridded_surfdata_filename, 'file')
    error(['File not found: ' mosart_gridded_surfdata_filename]);
end


ncid_inp = netcdf.open(mosart_gridded_surfdata_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(mosart_gridded_surfdata_filename);

[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

ID_region = reshape([1:latlen*lonlen]',[lonlen,latlen]);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1:ndims) = -1;

for idim = 1:ndims
    [dimname, dimlen] = netcdf.inqDim(ncid_inp,idim-1);
    %disp(['Inp: Dimension name:' dimname])
    
    switch dimname
        case {'lon','ncl1','ncl3','ncl5','ncl7'}
            dimid(idim) = netcdf.defDim(ncid_out,dimname,lonlen);
        case {'lat','ncl0','ncl2','ncl4','ncl6'}
            dimid(idim) = netcdf.defDim(ncid_out,dimname,latlen);
        otherwise
            disp(['Out: Dimension name:' dimname])
    end
    
end


% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimids); 
    varnames{ivar} = varname;
    
    for iatt = 1 : natts
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
    [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
    data = netcdf.getVar(ncid_inp,ivar-1);
    switch varname
        case {'lat'}
            netcdf.putVar(ncid_out,ivar-1,data(iymin:iymax));
        case {'lon'}
            netcdf.putVar(ncid_out,ivar-1,data(ixmin:ixmax));
        case {'ID'}
            netcdf.putVar(ncid_out,ivar-1,ID_region);
        case {'dnID'}
            dnID_temp = dnID(ixmin:ixmax,iymin:iymax);
            ID_temp   = ID(ixmin:ixmax,iymin:iymax);
            dnID_region = NaN(lonlen,latlen);
            for i = 1 : lonlen
                for j = 1 : latlen
                    if dnID_temp(i,j) == -9999
                        dnID_region(i,j) = -9999;
                    else
                        [ii,jj] = find(ID_temp == dnID_temp(i,j));
                        if isempty(ii)
                            dnID_region(i) = -9999;
                        elseif length(ii) == 1
                            dnID_region(i,j) = ID_region(ii,jj);
                        else
                            error('Multiple dnID is found, not possible!!!');
                        end
                    end
                end
            end
            netcdf.putVar(ncid_out,ivar-1,dnID_region);

        otherwise
            netcdf.putVar(ncid_out,ivar-1,data(ixmin:ixmax,iymin:iymax));
    end
end

% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

end

