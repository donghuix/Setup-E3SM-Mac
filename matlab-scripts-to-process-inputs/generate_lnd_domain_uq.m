function fname_out = generate_lnd_domain_uq(domain_gridded_filename,fname_out,ntot)
    
    ncid_inp = netcdf.open(domain_gridded_filename,'NC_NOWRITE');
    ncid_out = netcdf.create(fname_out,'NC_CLOBBER');
    [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);
    dimid = netcdf.inqDimID(ncid_inp,'ni');
    [~, ncells] = netcdf.inqDim(ncid_inp,dimid);
    
    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    %
    %                           Define dimensions
    %
    % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    dimid(1) = netcdf.defDim(ncid_out,'n',ntot*ncells);
    dimid(2) = netcdf.defDim(ncid_out,'ni',ntot*ncells);
    dimid(3) = netcdf.defDim(ncid_out,'nj',1);
    dimid(4) = netcdf.defDim(ncid_out,'nv',4);

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
            case {'xv','yv'}
                data = repmat(data,1,ntot);
            otherwise
                data = repmat(data,ntot,1);
        end
        netcdf.putVar(ncid_out,ivar-1,data);
    end

    netcdf.close(ncid_inp);
    netcdf.close(ncid_out);
end

