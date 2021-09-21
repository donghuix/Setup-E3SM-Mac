function fname_out = generate_mosart_input(mosart_gridded_surfdata_filename, ...
         out_netcdf_dir,mosart_usrdat_name,lat,lon,xv,yv,fdir,frac,gxr,nr,rslp, ...
         rlen,rdep,rwid,twid,hslp,nh,areatotal2)
%This script is to generate MOSART input file with required parameters
re = 6.37122e6;

[m,n] = size(gxr);
mask = zeros(m,n);
mask(gxr > 0) = 1;

[ID, dnID, fdir, gmask, badID] = fdir2dnID(fdir);
area = areaint(yv,xv).*4.*pi.*(re^2);

fname_out = sprintf('%s/MOSART_%s_%s.nc',out_netcdf_dir,mosart_usrdat_name,datestr(now, 'cyymmdd'));
disp(['  MOSART_dataset: ' fname_out])

ncid_inp = netcdf.open(mosart_gridded_surfdata_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(mosart_gridded_surfdata_filename);
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

dimid(1) = netcdf.defDim(ncid_out,'gridcell',sum(in(:)));

for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    if strcmp(varname,'latixy')
       ivar_lat = ivar;
    elseif strcmp(varname,'longxy')
       ivar_lon = ivar;
    end
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1));
    varnames{ivar} = varname;
    for iatt = 1 : natts
        attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
end

for ivar = 1:nvars
    [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
    switch varname
        case {'latixy','lat'}
            netcdf.putVar(ncid_out,ivar-1,lat);
        case {'longxy','lon'}
            netcdf.putVar(ncid_out,ivar-1,lon);
        case {'ID'}
            netcdf.putVar(ncid_out,ivar-1,ID);
        case {'dnID'}
%             dnID(~in) = -9999;
            netcdf.putVar(ncid_out,ivar-1,dnID);
        case {'fdir'}
            netcdf.putVar(ncid_out,ivar-1,fdir(in));
        case {'frac'}
            frac(frac > 0) = 1; % only contains 0 or 1; 
            netcdf.putVar(ncid_out,ivar-1,frac);
        case {'rslp','tslp'}
            % Li, H et al. 2013 assumed subnetwork slope is 
            % equal to that of main channel
            netcdf.putVar(ncid_out,ivar-1,rslp);
        case {'rlen'}
            netcdf.putVar(ncid_out,ivar-1,rlen);
        case {'rdep'}
            netcdf.putVar(ncid_out,ivar-1,rdep);
        case {'rwid'}
            netcdf.putVar(ncid_out,ivar-1,rwid);
        case {'rwid0'}
            % Li, H et al. 2013 assumed floodplain width is 5 times of the
            % channel width
            netcdf.putVar(ncid_out,ivar-1,5.*rwid);
        case {'gxr'}
            netcdf.putVar(ncid_out,ivar-1,gxr);
        case {'hslp'}
            netcdf.putVar(ncid_out,ivar-1,hslp);
        case {'twid'}
            netcdf.putVar(ncid_out,ivar-1,twid);
        case {'area'}
             netcdf.putVar(ncid_out,ivar-1,area); % m^2
        case {'ele0','ele1','ele2','ele3','ele4','ele5','ele6','ele7', ...
              'ele8','ele9','ele10'}
            [m,n] = size(fdir);
            tmp = zeros(m,n);
            netcdf.putVar(ncid_out,ivar-1,tmp(in));
        case {'nt','nr'}
            % Li, H et al. 2013 assumed subnetwork manning coefficient is 
            % equal to that of main channel
            netcdf.putVar(ncid_out,ivar-1,nr);
        case {'nh'}
            % Li, H et al. 2013 assumed nh=0.4
            netcdf.putVar(ncid_out,ivar-1,nh);
        case {'areaTotal2','areaTotal'}
            % areaTotal2 is upstream drainage area calculated based on 
            % single downstream method, should be very similar to areaTotal
            % assume areaTotal2 = areaTotal here
            netcdf.putVar(ncid_out,ivar-1,areatotal2);
        otherwise
            stop('Something wrong');
    end
end

% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

show_river_network(fname_out);

end

