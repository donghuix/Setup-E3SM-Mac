function generate_lnd_surface_uq(surface_gridded_filename,fname_out,ntot, ...
                                 fdrain,max_drain,ice_imped,snoalb_factor,fover, ...
                                 fmax,bsw,sucsat,xksat,watsat,fc,mu,slopebeta,slopemax)
    
    ncid_inp = netcdf.open(surface_gridded_filename,'NC_NOWRITE');
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
    [ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);
    for idim = 1:ndims
        [dimname, dimlen] = netcdf.inqDim(ncid_inp,idim-1);
        %disp(['Inp: Dimension name:' dimname])

        switch dimname
            case {'gridcell'}
                dimid(idim) = netcdf.defDim(ncid_out,dimname,ncells*ntot);
            case 'time'
                %disp(['Out: Dimension name:' dimname])
                %dimid(idim) = netcdf.defDim(ncid_out,dimname,netcdf.getConstant('NC_UNLIMITED'));
                dimid(idim) = netcdf.defDim(ncid_out,dimname,12);
            otherwise
                %disp(['Out: Dimension name:' dimname])
                for ii=1:length(info_inp.Dimensions)
                    if (strcmp(info_inp.Dimensions(ii).Name,dimname) == 1)
                        [dimname, dimlen] = netcdf.inqDim(ncid_inp,ii-1);
                    end
                end
                dimid(idim) = netcdf.defDim(ncid_out,dimname,dimlen);
                %disp(['Out: Dimension name:' dimname ', dimlen = ' num2str(dimlen)])
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
        switch length(vardimids)
            case 0
                disp(data);
            case 1
                if strcmp(varname,'natpft') || strcmp(varname,'time')
%                     continue;
                else
                    data = repmat(data,ntot,1);
                end
            case 2
                data = repmat(data,ntot,1);
            case 3
                data = repmat(data,ntot,1,1);
            otherwise
                error('check dimension');
        end
        %fprintf([varname ': ' num2str(size(data)) '\n']);
        if strcmp(varname,'fdrain')
            disp('fdrain is found!!!\n\n');
            data = fdrain;
        end
        if strcmp(varname,'max_drain')
            disp('max_drain is found!!!\n\n');
            data = max_drain;
        end
        if strcmp(varname,'ice_imped')
            disp('ice_imped is found!!!\n\n');
            data = ice_imped;
        end
        if strcmp(varname,'snoalb_factor')
            disp('snoalb_factor is found!!!\n\n');
            data = snoalb_factor;
        end
        if strcmp(varname,'fover')
            disp('fover is found!!!\n\n');
            data = fover;
        end
        if strcmp(varname,'FMAX')
            disp('fmax is found!!!\n\n');
            data = fmax;
        end
        if strcmp(varname,'bsw')
            disp('bsw is found!!!\n\n');
            data = bsw;
        end
        if strcmp(varname,'sucsat')
            disp('sucsat is found!!!\n\n');
            data = sucsat;
        end
        if strcmp(varname,'xksat')
            disp('xksat is found!!!\n\n');
            data = xksat;
        end
        if strcmp(varname,'watsat')
            disp('watsat is found!!!\n\n');
            data = watsat;
        end
        if strcmp(varname,'pc')
            disp('pc is found!!!\n\n');
            data = fc;
        end
        if strcmp(varname,'mu')
            disp('mu is found!!!\n\n');
            data = mu;
        end
        if strcmp(varname,'slopebeta')
            disp('slopebeta is found!!!\n\n');
            data = slopebeta;
        end
        if strcmp(varname,'slopemax')
            disp('slopemax is found!!!\n\n');
            data = slopemax;
        end
        netcdf.putVar(ncid_out,ivar-1,data);
    end

    netcdf.close(ncid_inp);
    netcdf.close(ncid_out);
end

