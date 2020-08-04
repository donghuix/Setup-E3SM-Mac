% ======================================================================= %
% Creates an unstructured input netCDF file of MOSART for E3SM.
%
% # INPUTS #
% in: if in is logical matrix, it indicates which cells to extract
%     if in is a shapefile, it is the boundary to clip the mesh
% mosart_gridded_surfdata_filename: Global gridded MOSART input data file
% out_netcdf_dir: Directory where MOSART input dataset will be saved
% mosart_usrdat_name: User defined name for MOSART dataset
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 06/11/2020
% ======================================================================= %
function fname_out = CreateMOSARTUgridInputForE3SM2(...
                    in, ...
                    mosart_gridded_surfdata_filename, ...
                    out_netcdf_dir, mosart_usrdat_name)

latixy = ncread(mosart_gridded_surfdata_filename,'latixy');
longxy = ncread(mosart_gridded_surfdata_filename,'longxy');

if ischar(in)
    if ~isexist(in)
        error([in ' does not exist!'])
    else
        S = shaperead(in); clear in;
    end
    in = inpolygon(longxy,latixy,S.X,S.Y);
end

ID     = ncread(mosart_gridded_surfdata_filename,'ID');
dnID   = ncread(mosart_gridded_surfdata_filename,'dnID');
ID_region = 1 : sum(in(:));
ID_region = ID_region';

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
dimid(1) = netcdf.defDim(ncid_out,'gridcell',sum(in(:)));
% dimid(1) = netcdf.defDim(ncid_out,'lat',1);
% dimid(2) = netcdf.defDim(ncid_out,'lon',sum(in(:)));

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
read_ele = 0;
for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1));
%     switch varname
%         case {'lat'}
%             varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1));
%         case {'lon'}
%             varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(2));
%         otherwise
%             varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,[dimid(2),dimid(1)]);
%     end   
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
%{
if strcmp(getenv('add_area'),'yes')
    disp(getenv('filename'));
    ncid_area = netcdf.open(getenv('filename'),'NC_NOWRITE');
    %area = ncread(getenv('filename'),'area');
    ivar = 1;
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_area,ivar-1);
    while strcmp(varname,'area') ~= 1
        ivar = ivar + 1;
        [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_area,ivar-1);
    end

    assert(strcmp(varname,'area'));
    varid(nvars+1) = netcdf.defVar(ncid_out,varname,xtype,[dimid(2),dimid(1)]);
    varnames{nvars+1} = varname;
    
    for iatt = 1 : natts
        attname = netcdf.inqAttName(ncid_area,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
    
end
%}

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
        case {'lat','lon'}
            continue;
        case {'ID'}
            netcdf.putVar(ncid_out,ivar-1,ID_region);
        case {'dnID'}
            dnID_temp = dnID(in);
            ID_temp   = ID(in);
            dnID_region = NaN(length(dnID_temp),1);
            for i = 1 : length(dnID_temp)
                if dnID_temp(i) == -9999
                    dnID_region(i) = -9999;
                else
                    ind = find(ID_temp == dnID_temp(i));
                    if isempty(ind)
                        dnID_region(i) = -9999;
                    else
                        dnID_region(i) = ID_region(ind);
                    end
                end
            end
            netcdf.putVar(ncid_out,ivar-1,dnID_region);
        otherwise
            [varname2,vartype2,vardimids2,varnatts2]=netcdf.inqVar(ncid_out,ivar-1);
            netcdf.putVar(ncid_out,ivar-1,data(in));
    end
end

if read_ele == 1
ele = zeros(sum(in(:)),11);
    for i = 1 : 11
        data = ncread(mosart_gridded_surfdata_filename,strcat('ele',num2str(i-1)));
        ele(:,i) = data(in);
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
