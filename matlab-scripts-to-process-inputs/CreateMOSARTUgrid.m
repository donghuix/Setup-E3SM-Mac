% ======================================================================= %
% Creates an unstructured input netCDF file of MOSART for E3SM.
%
% # INPUTS #
% in: if in is logical matrix, it indicates which cells to extract
%     if in is a shapefile, it is the boundary to clip the mesh
%     if in is a structure data, create a dummy MOSART input file
%        * in.lon, in.lat, in.area
% mosart_gridded_filename:Gridded MOSART input data file to interpolate on (template)
% out_netcdf_dir:         Directory where MOSART input dataset will be saved
% mosart_usrdat_name:     User defined name for MOSART dataset
% include_all_cells:      (optional), if include_all_cells = 1, extract all the gird cells defined by in
%                                     if include_all_cells = 0, only extract the grid cells corrsponding to the outlet
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 06/11/2020
% ======================================================================= %
function fname_out = CreateMOSARTUgrid(in,mosart_gridded_filename, out_netcdf_dir, ...
                                       mosart_usrdat_name,include_all_cells)

if nargin == 4
    include_all_cells = 0; % 0: find all the cells corresponding to the outlet
                           % 1: use all the cells in the areas
end

generate_dummy = 0;
latixy = ncread(mosart_gridded_filename,'latixy');
longxy = ncread(mosart_gridded_filename,'longxy');
area      = ncread(mosart_gridded_filename,'area');
areaTotal = ncread(mosart_gridded_filename,'areaTotal2');

% if in is provided as a shapefile, using the watershed boundary to find
% the index inside
if ischar(in)
    if ~isexist(in)
        error([in ' does not exist!'])
    else
        S = shaperead(in); clear in;
    end
    in = inpolygon(longxy,latixy,S.X,S.Y);
end

if islogical(in)
    ncells = sum(in(:)); % number of grid cells in the domain
else
    ncells = length(in);
end

if isstruct(in)
    fprintf('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n');
    fprintf('\nCreating Dummy MOSART Input File!\n');
    fprintf('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n');
    generate_dummy = 1;
    ncells = length(in.lon);
    lon_region = in.lon;
    lat_region = in.lat;
    areaTotal_region = in.area;
    area_region      = in.area;
else
    lon_region       = longxy(in);
    lat_region       = latixy(in);
    areaTotal_region = areaTotal(in);
    area_region      = area(in);
    ioutlet          = find(areaTotal_region == max(areaTotal_region));
end

ID     = ncread(mosart_gridded_filename,'ID');
dnID   = ncread(mosart_gridded_filename,'dnID');
ID_region = 1 : ncells;
ID_region = ID_region';

% MOSART parameter name
fname_out = sprintf('%s/MOSART_%s_%s.nc',out_netcdf_dir,mosart_usrdat_name,datestr(now, 'cyymmdd'));
disp(['  MOSART_dataset: ' fname_out])

% Check if the file is available
if ~exist(mosart_gridded_filename, 'file')
    error(['File not found: ' mosart_gridded_filename]);
end
    
ncid_inp = netcdf.open(mosart_gridded_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(mosart_gridded_filename);

[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1) = netcdf.defDim(ncid_out,'gridcell',ncells);
dimid(2) = netcdf.defDim(ncid_out,'nele',11);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
read_ele = 0;
found_ele = 0;
for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    if strcmp(varname,'ele')
        varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,[dimid(1),dimid(2)]);
        found_ele = 1;
    else
        varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1));
    end
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
 
if read_ele == 1 && found_ele == 0
    fprintf(['ele not found, estimate from ele0...ele10']);
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
netcdf.putAtt(ncid_out,varid,'Created_on' ,string(datetime('now')));
if generate_dummy
else
    netcdf.putAtt(ncid_out,varid,'Interpolate_from' ,mosart_gridded_filename);
end
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
            netcdf.putVar(ncid_out,ivar-1,lat_region);
        case {'latixy'}
            netcdf.putVar(ncid_out,ivar-1,lat_region);
        case {'lon'}
            netcdf.putVar(ncid_out,ivar-1,lon_region);
        case {'longxy'}
            netcdf.putVar(ncid_out,ivar-1,lon_region);
        case {'area'}
            netcdf.putVar(ncid_out,ivar-1,area_region);
        case {'areaTotal2'}
            netcdf.putVar(ncid_out,ivar-1,areaTotal_region);
        case {'ele'}
            if generate_dummy
                ele_region = NaN(ncells,11);
                for ii = 1 : ncells
                    ele_region(ii,:) = 1 : 11;
                end
            else
                ele_region = NaN(ncells,11);
                for i = 1 : 11
                    tmp = data(:,:,i);
                    tmp = tmp(in);
                    assert(length(tmp) == ncells);
                    ele_region(:,i) = tmp;
                end
            end
            netcdf.putVar(ncid_out,ivar-1,ele_region);
        case {'ID'}
            netcdf.putVar(ncid_out,ivar-1,ID_region);
        case {'dnID'}
            if generate_dummy
                dnID_region = ones(ncells,1).*-9999;
            else
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
                if include_all_cells == 0
                    for ict = 1 : length(dnID_region)
                        idn = ict;
                        while dnID_region(idn) ~= -9999
                            idn = dnID_region(idn);
                        end
                        if idn ~= ioutlet
                            dnID_region(ict) = -9999;
                        end
                    end
                end
            end
            netcdf.putVar(ncid_out,ivar-1,dnID_region);
        otherwise
            [varname2,vartype2,vardimids2,varnatts2]=netcdf.inqVar(ncid_out,ivar-1);
            if generate_dummy
                dummyvalue = median(data(:));
                if isa(dummyvalue,'int32')
                    data_region = cast(ones(ncells,1),'int32') .* dummyvalue;
                else
                    data_region = ones(ncells,1) .* dummyvalue;
                end
            else
                data_region = data(in);
            end
            netcdf.putVar(ncid_out,ivar-1,data_region);
    end
end

if read_ele == 1 && found_ele == 0
ele = zeros(ncells,11);
    for i = 1 : 11
        data = ncread(mosart_gridded_filename,strcat('ele',num2str(i-1)));
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
