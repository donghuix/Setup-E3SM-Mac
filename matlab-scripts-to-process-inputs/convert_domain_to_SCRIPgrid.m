function ncid = convert_domain_to_SCRIPgrid(fname_in,fname_out)

xc = ncread(fname_in,'xc');
yc = ncread(fname_in,'yc');
xv = ncread(fname_in,'xv');
yv = ncread(fname_in,'yv');
mask = ncread(fname_in,'mask');
area = ncread(fname_in,'area');

if length(size(xc)) == 2 && size(xc,2) ~= 1
    grid_rank = 2;
    [m,n] = size(xc);
else
    grid_rank = 1;
    m = length(xc);
    n = 1;
end

grid_size = m*n;
grid_corners = size(xv,1);

grid_center_lat = NaN(grid_size,1);
grid_center_lon = NaN(grid_size,1);
grid_corner_lat = NaN(grid_corners,grid_size);
grid_corner_lon = NaN(grid_corners,grid_size);
grid_imask      = NaN(grid_size,1);
grid_area       = NaN(grid_size,1);

if grid_rank == 1
    grid_center_lat = yc;
    grid_center_lon = xc;
    grid_corner_lat = yv;
    grid_corner_lon = xv;
    grid_imask      = mask;
    grid_area       = area;
elseif grid_rank == 2
    grid_center_lat = yc(:);
    grid_center_lon = xc(:);
    grid_imask      = mask(:);
    grid_area       = area(:);
    for i = 1 : grid_corners
        tmp = yv(i,:,:);
        grid_corner_lat(i,:) = tmp(:);
        tmp = xv(i,:,:);
        grid_corner_lon(i,:) = tmp(:);
    end
end

ncid = netcdf.create(fname_out,'NC_CLOBBER');

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    dimid(1) = netcdf.defDim(ncid,'grid_size',grid_size);
    dimid(2) = netcdf.defDim(ncid,'grid_corners', grid_corners);
    dimid(3) = netcdf.defDim(ncid,'grid_rank', grid_rank);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ivar = 1;
varid(1) = netcdf.defVar(ncid,'grid_dims','int',dimid(3)); 

ivar = 2;
varid(2) = netcdf.defVar(ncid,'grid_center_lat','double',dimid(1)); 
netcdf.putAtt(ncid,ivar-1,'units','degrees');

ivar = 3;
varid(3) = netcdf.defVar(ncid,'grid_center_lon','double',dimid(1)); 
netcdf.putAtt(ncid,ivar-1,'units','degrees');

ivar = 4;
varid(4) = netcdf.defVar(ncid,'grid_imask','int',dimid(1)); 
netcdf.putAtt(ncid,ivar-1,'units','unitless');

ivar = 5;
varid(5) = netcdf.defVar(ncid,'grid_corner_lat','double',[dimid(2),dimid(1)]); 
netcdf.putAtt(ncid,ivar-1,'units','degrees');

ivar = 6;
varid(6) = netcdf.defVar(ncid,'grid_corner_lon','double',[dimid(2),dimid(1)]); 
netcdf.putAtt(ncid,ivar-1,'units','degrees');

ivar = 7;
varid(7) = netcdf.defVar(ncid,'grid_area','double',dimid(1)); 
netcdf.putAtt(ncid,ivar-1,'units','radians^2');

varid2 = netcdf.getConstant('GLOBAL');
[~,user_name]=system('echo $USER');
netcdf.putAtt(ncid,varid2,'Created_by' ,user_name(1:end-1));
netcdf.putAtt(ncid,varid2,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
netcdf.endDef(ncid);

if grid_rank == 1
    netcdf.putVar(ncid,1-1,[m]);
elseif grid_rank == 2
    netcdf.putVar(ncid,1-1,[m;n]);
end
netcdf.putVar(ncid,2-1,grid_center_lat);
netcdf.putVar(ncid,3-1,grid_center_lon);
netcdf.putVar(ncid,4-1,grid_imask);
netcdf.putVar(ncid,5-1,grid_corner_lat);
netcdf.putVar(ncid,6-1,grid_corner_lon);
netcdf.putVar(ncid,7-1,grid_area);

netcdf.close(ncid);
    
end

