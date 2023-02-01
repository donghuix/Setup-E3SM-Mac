% ======================================================================= %
% Creates a structured domain netCDF file of ELM for E3Sm.
%
% # INPUTS #
%      xmin, xmax, ymin, ymax: coordinates of the rectangle corners to clip
%      clm_gridded_domain_filename = Default ELM domain file name
%      out_netcdf_dir = Directory where ELM domain dataset will be saved
%      clm_usrdat_name = User defined name for ELM dataset
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 06/11/2020
% ======================================================================= %
function fname_out = CreateDomainSgridInputForE3SM(...
                    xmin, xmax, ymin, ymax,        ...
                    clm_gridded_domain_filename,   ...
                    out_netcdf_dir,                ...
                    clm_usrdat_name)

% Default dimension is lon * lat
longxy = ncread(clm_gridded_domain_filename,'xc');
latixy = ncread(clm_gridded_domain_filename,'yc');
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

fname_out = sprintf('%s/domain_%s_%s_%s.nc',...
            out_netcdf_dir,clm_usrdat_name,midstr,datestr(now, 'cyymmdd'));

disp(['  domain: ' fname_out])

% Check if the file is available
if ~exist(clm_gridded_domain_filename, 'file')
    error(['File not found: ' clm_gridded_domain_filename]);
end

ncid_inp = netcdf.open(clm_gridded_domain_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(clm_gridded_domain_filename);

[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

for ii = 1:ndims
    [dimname, ndim] = netcdf.inqDim(ncid_inp,ii-1);
    switch dimname
        case 'ni'
            ndim = lonlen;
        case 'nj'
            ndim = latlen;
        case 'n'
            ndim = lonlen*latlen;
    end
    dimid(ii) = netcdf.defDim(ncid_out,dimname,ndim);
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
debug = 0;
for ivar = 1:nvars
    
    data = netcdf.getVar(ncid_inp,ivar-1);
    [varname,vartype,vardimids,varnatts] = netcdf.inqVar(ncid_inp,ivar-1);
    
    if strcmp(varname,'xv') || strcmp(varname,'yv')
        netcdf.putVar(ncid_out,ivar-1,data(:,ixmin:ixmax,iymin:iymax));
    elseif strcmp(varname,'frac') || strcmp(varname,'mask')
        if debug == 1
            netcdf.putVar(ncid_out,ivar-1,ones(lonlen,latlen));
        else
            netcdf.putVar(ncid_out,ivar-1,data(ixmin:ixmax,iymin:iymax));
        end
    else
        netcdf.putVar(ncid_out,ivar-1,data(ixmin:ixmax,iymin:iymax));
    end
end

% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

end

