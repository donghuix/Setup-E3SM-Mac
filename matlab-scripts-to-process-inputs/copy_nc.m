function copy_nc(fname_in,fname_out,ntot)
    ncid_inp = netcdf.open(fname_in,'NC_NOWRITE');
    ncid_out = netcdf.create(fname_out,'64BIT_OFFSET');

    [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);
    dimid = netcdf.inqDimID(ncid_inp,'gridcell');
    [~, ncells] = netcdf.inqDim(ncid_inp,dimid);
    
    info_inp = ncinfo(surface_gridded_filename);
    
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    for idim = 1:ndims
        [dimname, dimlen] = netcdf.inqDim(ncid_inp,idim-1);
        switch dimname
            case {'gridcell'}
                dimid(idim) = netcdf.defDim(ncid_out,dimname,ncells*ntot);
            case 'time'
                dimid(idim) = netcdf.defDim(ncid_out,dimname,86);
            otherwise
                for ii=1:length(info_inp.Dimensions)
                    if (strcmp(info_inp.Dimensions(ii).Name,dimname) == 1)
                        [dimname, dimlen] = netcdf.inqDim(ncid_inp,ii-1);
                    end
                end
                dimid(idim) = netcdf.defDim(ncid_out,dimname,dimlen);
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
        if length(vardimids) == 1 && vardimids == 0
            data = repmat(data,ntot,1);
        elseif length(vardimids) == 2 && vardimids(1) == 0
            data = repmat(data,ntot,1);
        elseif length(vardimids) == 3 && vardimids(1) == 0
            data = repmat(data,ntot,1,1);
        elseif length(vardimids) == 4 && vardimids(1) == 0
            data = repmat(data,ntot,1,1,1);
        end
        netcdf.putVar(ncid_out,ivar-1,data);
    end
    netcdf.close(ncid_inp);
    netcdf.close(ncid_out);
end