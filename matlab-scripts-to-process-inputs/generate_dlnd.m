function generate_dlnd(QDRAI,QOVER,lat,lon,time,startdate,isleap,fname_out)

% startdate should be yyyy-mm-dd format
    
    QRUNOFF = QOVER + QDRAI; % total runoff is the sum of surface and subsurface runoff
    [nlon,nlat,nt] = size(QDRAI);
    disp(nlon)
    disp(nlat)
    disp(nt)
    assert(nlon == length(lon) && nlat == length(lat) && nt == length(time));
    
    netcdf.setDefaultFormat('NC_FORMAT_64BIT'); % To write for large file
    ncid_out = netcdf.create(fname_out,'NC_CLOBBER');
    
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    dimid(1) = netcdf.defDim(ncid_out,'lat',nlat);
    dimid(2) = netcdf.defDim(ncid_out,'lon',nlon);
    dimid(3) = netcdf.defDim(ncid_out,'time',nt);
    
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    varnames = {'QDRAI', 'QOVER', 'QRUNOFF', 'lat', 'lon', 'time'};
    nvars = length(varnames);
    ivar = 1;
    varid(ivar) = netcdf.defVar(ncid_out,'QDRAI',6,[dimid(2),dimid(1),dimid(3)]); 
    netcdf.putAtt(ncid_out,ivar-1,'standard_name','subsurface runoff');
    netcdf.putAtt(ncid_out,ivar-1,'units','mm/s');
    
    ivar = 2;
    varid(ivar) = netcdf.defVar(ncid_out,'QOVER',6,[dimid(2),dimid(1),dimid(3)]); 
    netcdf.putAtt(ncid_out,ivar-1,'standard_name','surface runoff');
    netcdf.putAtt(ncid_out,ivar-1,'units','mm/s');
    
    ivar = 3;
    varid(ivar) = netcdf.defVar(ncid_out,'QRUNOFF',6,[dimid(2),dimid(1),dimid(3)]); 
    netcdf.putAtt(ncid_out,ivar-1,'standard_name','total runoff');
    netcdf.putAtt(ncid_out,ivar-1,'units','mm/s');
    
    ivar = 4;
    varid(ivar) = netcdf.defVar(ncid_out,'lat',6,dimid(1)); 
    netcdf.putAtt(ncid_out,ivar-1,'standard_name','latitude');
    netcdf.putAtt(ncid_out,ivar-1,'long_name','latitude');
    netcdf.putAtt(ncid_out,ivar-1,'units','degrees_north');
    netcdf.putAtt(ncid_out,ivar-1,'axis','Y');
    
    ivar = 5;
    varid(ivar) = netcdf.defVar(ncid_out,'lon',6,dimid(2)); 
    netcdf.putAtt(ncid_out,ivar-1,'standard_name','longitude');
    netcdf.putAtt(ncid_out,ivar-1,'long_name','longitude');
    netcdf.putAtt(ncid_out,ivar-1,'units','degrees_east');
    netcdf.putAtt(ncid_out,ivar-1,'axis','X');
    
    ivar = 6;
    varid(ivar) = netcdf.defVar(ncid_out,'time',6,dimid(3)); 
    netcdf.putAtt(ncid_out,ivar-1,'standard_name','time');
    if isleap
        netcdf.putAtt(ncid_out,ivar-1,'calendar','gregorian');
    else
        netcdf.putAtt(ncid_out,ivar-1,'calendar','noleap');
    end
    netcdf.putAtt(ncid_out,ivar-1,'units',['days since ' startdate ' 00:00:00']);
    netcdf.putAtt(ncid_out,ivar-1,'axis','T');
    
    varidg = netcdf.getConstant('GLOBAL');

    [~,user_name]=system('echo $USER');
    netcdf.putAtt(ncid_out,varidg,'Created_by' ,user_name(1:end-1));
    netcdf.putAtt(ncid_out,varidg,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
    netcdf.endDef(ncid_out);
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Copy variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    ivar = 1;
    netcdf.putVar(ncid_out,ivar-1,QDRAI);
    ivar = 2;
    netcdf.putVar(ncid_out,ivar-1,QOVER);
    ivar = 3;
    netcdf.putVar(ncid_out,ivar-1,QRUNOFF);
    ivar = 4;
    netcdf.putVar(ncid_out,ivar-1,lat);
    ivar = 5;
    netcdf.putVar(ncid_out,ivar-1,lon);
    ivar = 6;
    netcdf.putVar(ncid_out,ivar-1,time);
    
    netcdf.close(ncid_out);
    
end

