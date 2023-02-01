% ======================================================================= %
% Creates an unstructured input netCDF file of MOSART for E3SM.
%
% # INPUTS #
% mosart_gridded_surfdata_filename: Global gridded MOSART input data file
% out_netcdf_dir:                   Directory for the output
% mosart_usrdat_name:               User defined name for MOSART dataset
% user_defined_vars:                User defined variables for the dataset
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 08/06/2020
% ======================================================================= %
function fname_out = CreateMOSARTUgridInputForE3SM3(    ...
                    mosart_gridded_surfdata_filename,   ...
                    out_netcdf_dir, mosart_usrdat_name, ...
                    user_defined_vars)

latixy = ncread(mosart_gridded_surfdata_filename,'latixy');
longxy = ncread(mosart_gridded_surfdata_filename,'longxy');
latixy_region = user_defined_vars.latixy;
longxy_region = user_defined_vars.longxy;

fname_out = sprintf('%s/MOSART_%s_%s.nc',out_netcdf_dir,mosart_usrdat_name,datestr(now, 'cyymmdd'));
disp(['  MOSART_dataset: ' fname_out])

% Check if the file is available
if ~exist(mosart_gridded_surfdata_filename, 'file')
    error(['File not found: ' mosart_gridded_surfdata_filename]);
end
    
ncid_inp = netcdf.open(mosart_gridded_surfdata_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(mosart_gridded_surfdata_filename);

[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1) = netcdf.defDim(ncid_out,'gridcell',length(latixy_region));

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
read_ele = 0;
for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1)); 
    varnames{ivar} = varname;
    if strcmp(varname, 'ele0')
        read_ele = 1;
    end
    for iatt = 1 : natts
        attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
    
end
if read_ele == 1
    dimid(2) = netcdf.defDim(ncid_out,'nele',11);
    varid(nvars+1) = netcdf.defVar(ncid_out,'ele',xtype,[dimid(1),dimid(2)]);
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
    if isfield(user_defined_vars,varname)
        netcdf.putVar(ncid_out,ivar-1,user_defined_vars.(varname));
        fprintf([varname ' is copied!\n']);
    elseif strcmp(varname,'lat')
        netcdf.putVar(ncid_out,ivar-1,latixy_region);
    elseif strcmp(varname,'lon')
        netcdf.putVar(ncid_out,ivar-1,longxy_region);
    else
        datav = griddata(longxy,latixy,data,longxy_region,latixy_region,'nearest');
        %[varname2,vartype2,vardimids2,varnatts2]=netcdf.inqVar(ncid_out,ivar-1);
        netcdf.putVar(ncid_out,ivar-1,datav);
    end
end

if read_ele == 1
ele = zeros(length(latixy_region),11);
    for i = 1 : 11
        data = ncread(mosart_gridded_surfdata_filename,strcat('ele',num2str(i-1)));
        ele(:,i) = griddata(longxy,latixy,data,longxy_region,latixy_region,'nearest');
    end
    netcdf.putVar(ncid_out,nvars,ele);
end

if strcmp(getenv('add_area'),'yes')
    area = ncread(getenv('filename'),'area');
    netcdf.putVar(ncid_out,nvars,area(in));
    netcdf.close(ncid_area);
end
% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

end
