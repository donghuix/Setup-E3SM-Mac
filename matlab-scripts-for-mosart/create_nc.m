function ncid = create_nc(fname,nyears,yr_start,res,varname,data,units)
    ncid = netcdf.create(fname,'NC_CLOBBER');
    month_bnd = [0;31;59;90;120;151;181;212;243;273;304;334;365];
    tbnd = NaN(nyears*12,2);
    for i = 1 : nyears
        tbnd((i-1)*12+1:i*12,1) = (i-1)*365 + month_bnd(1:end-1);
        tbnd((i-1)*12+1:i*12,2) = (i-1)*365 + month_bnd(2:end);
    end

    tbnd = tbnd + (yr_start-1850)*365;
    t = mean(tbnd,2);
    latbnd(:,1) = -90 : res : 90-res;
    latbnd(:,2) = -90+res : res : 90;
    lonbnd(:,1) = -180 : res : 180-res;
    lonbnd(:,2) = -180+res : res : 180;
    lat = mean(latbnd,2);
    lon = mean(lonbnd,2);
    
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    dimid(1) = netcdf.defDim(ncid,'time',length(t));
    dimid(2) = netcdf.defDim(ncid,'lat', length(lat));
    dimid(3) = netcdf.defDim(ncid,'lon', length(lon));
    dimid(4) = netcdf.defDim(ncid,'nb',  2);
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ivar = 1;
varid(1) = netcdf.defVar(ncid,'time',6,[dimid(1)]); 
netcdf.putAtt(ncid,ivar-1,'calendar','noleap');
netcdf.putAtt(ncid,ivar-1,'units','days since 1850-01-01');
netcdf.putAtt(ncid,ivar-1,'bounds','time_bounds');

ivar = 2;
varid(2) = netcdf.defVar(ncid,'time_bounds',6,[dimid(4),dimid(1)]); 

ivar = 3;
varid(3) = netcdf.defVar(ncid,'lat',6,[dimid(2)]); 
netcdf.putAtt(ncid,ivar-1,'long_name','longitude of grid cell verticies');
netcdf.putAtt(ncid,ivar-1,'units','degrees_north');

ivar = 4;
varid(4) = netcdf.defVar(ncid,'lat_bounds',6,[dimid(4),dimid(2)]); 

ivar = 5;
varid(5) = netcdf.defVar(ncid,'lon',6,[dimid(3)]); 
netcdf.putAtt(ncid,ivar-1,'units','degrees_north');

ivar = 6;
varid(6) = netcdf.defVar(ncid,'lon_bounds',6,[dimid(4),dimid(3)]); 

ivar = 7;
varid(7) = netcdf.defVar(ncid,varname,6,[dimid(3),dimid(2),dimid(1)]); 
netcdf.putAtt(ncid,ivar-1,'units',units);

varid = netcdf.getConstant('GLOBAL');
[~,user_name]=system('echo $USER');
netcdf.putAtt(ncid,varid,'Created_by' ,user_name(1:end-1));
netcdf.putAtt(ncid,varid,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
netcdf.endDef(ncid);

netcdf.putVar(ncid,1-1,t);
netcdf.putVar(ncid,2-1,tbnd');
netcdf.putVar(ncid,3-1,lat);
netcdf.putVar(ncid,4-1,latbnd');
netcdf.putVar(ncid,5-1,lon);
netcdf.putVar(ncid,6-1,lonbnd');
netcdf.putVar(ncid,7-1,data);

netcdf.close(ncid);
    
end

