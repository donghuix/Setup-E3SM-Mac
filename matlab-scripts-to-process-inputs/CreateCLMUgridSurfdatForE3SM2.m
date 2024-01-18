% ======================================================================= %
% Creates a structured surface-data netCDF file of ELM for E3Sm.
%
% # INPUTS #
%      in
%      clm_gridded_surfdata_filename = Gridded ELM surface data file
%      out_netcdf_dir = Directory where ELM surface dataset will be saved
%      clm_usrdat_name = User defined name for ELM dataset
% # ------ #
% 
% Donghui Xu (donghui.xu@pnnl.gov)
% 09/25/2020
% 02/24/2021: add three parameters for sensitivitiy analysis of runoff
%             timing. (Donghui Xu)
% 03/03/2021: add fover for sensitivity analysis. (Donghui Xu)
% ======================================================================= %
function fname_out = CreateCLMUgridSurfdatForE3SM2(  ...
                    in,                             ...
                    clm_gridded_surfdata_filename,  ...
                    out_netcdf_dir, clm_usrdat_name,...
                    fdrain,max_drain,ice_imped,snoalb_factor,fover, ...
                    fmax,bsw,sucsat,xksat,watsat,fc,mu,micro_sigma,kh2osfc)

write_fdrain = 0; write_max_drain = 0; write_ice_imped = 0; write_snoalb_factor = 0;
write_fover = 0; write_fmax = 0; write_bsw = 0; write_sucsat = 0; write_xksat = 0;
write_watsat = 0; write_fc = 0; write_mu = 0; write_micro_sigma = 0; write_kh2osfc = 0;

if ~isempty(fdrain); write_fdrain = 1;               end;
if ~isempty(max_drain); write_max_drain = 1;         end;
if ~isempty(ice_imped); write_ice_imped = 1;         end;
if ~isempty(snoalb_factor); write_snoalb_factor = 1; end;
if ~isempty(fover); write_fover = 1;                 end;
if ~isempty(fmax); write_fmax = 1;                   end;
if ~isempty(bsw); write_bsw = 1;                     end;
if ~isempty(sucsat); write_sucsat = 1;               end;
if ~isempty(xksat); write_xksat = 1;                 end;
if ~isempty(watsat); write_watsat = 1;               end;
if ~isempty(fc); write_fc = 1;                       end;
if ~isempty(mu); write_mu = 1;                       end;
if ~isempty(micro_sigma); write_micro_sigma = 1;     end;
if ~isempty(kh2osfc); write_kh2osfc = 1;             end;

% Default dimension is lon * lat
latixy = ncread(clm_gridded_surfdata_filename,'LATIXY');
longxy = ncread(clm_gridded_surfdata_filename,'LONGXY');
long_region = longxy(in);
lati_region = latixy(in);

fname_out = sprintf('%s/surfdata_%s_%s.nc',...
            out_netcdf_dir,clm_usrdat_name,datestr(now, 'cyymmdd'));
        
disp(['  surface_dataset: ' fname_out])

% Check if the file is available
if ~exist(clm_gridded_surfdata_filename, 'file')
    error(['File not found: ' mosart_gridded_surfdata_filename]);
end

% Check if the file is available
[s,~]=system(['ls ' clm_gridded_surfdata_filename]);

if (s ~= 0)
    error(['File not found: ' clm_gridded_surfdata_filename]);
end

ncid_inp = netcdf.open(clm_gridded_surfdata_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'64BIT_OFFSET'); 
% For large netcdf file, need to use '64BIT_OFFSET', previously use 'NC_CLOBBER'

info_inp = ncinfo(clm_gridded_surfdata_filename);

[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1:ndims) = -1;
lonlat_found = 0;

for idim = 1:ndims
    [dimname, dimlen] = netcdf.inqDim(ncid_inp,idim-1);
    %disp(['Inp: Dimension name:' dimname])
    
    switch dimname
        case 'gridcell'
            dimid(idim) = netcdf.defDim(ncid_out,dimname,length(in));
        case 'time'
            %disp(['Out: Dimension name:' dimname])
            dimid(idim) = netcdf.defDim(ncid_out,dimname,netcdf.getConstant('NC_UNLIMITED'));
        otherwise
            dimid(idim) = netcdf.defDim(ncid_out,dimname,dimlen);
    end
end

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for ivar = 1:nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimids);
    if strcmp(varname,'AREA')
        fdrain_dimids = dimids;
        fdrain_type = xtype;
    end
    if strcmp(varname,'PCT_SAND')
        sand_dimids = dimids;
    end
    varnames{ivar} = varname;
    %disp([num2str(ivar) ') varname : ' varname ' ' num2str(dimids)])
    
    for iatt = 1:natts
        attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
    
end
if write_fdrain
    ivar = nvars + 1;
    fdrainid = netcdf.defVar(ncid_out,'fdrain',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','subsurface drainage decay factor');
    netcdf.putAtt(ncid_out,ivar-1,'unites','m-1');
end
if write_max_drain
    ivar = ivar + 1;
    max_drain_id = netcdf.defVar(ncid_out,'max_drain',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','maximum bottom drainage rate');
    netcdf.putAtt(ncid_out,ivar-1,'unites','mm/s');
end
if write_ice_imped
    ivar = ivar + 1;
    ice_imped_id = netcdf.defVar(ncid_out,'ice_imped',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','parameter for ice impedance');
    netcdf.putAtt(ncid_out,ivar-1,'unites','m-1');
end
if write_snoalb_factor
    ivar = ivar + 1;
    ice_imped_id = netcdf.defVar(ncid_out,'snoalb_factor',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','parameter for snow albedo');
    netcdf.putAtt(ncid_out,ivar-1,'unites','[0-1]');
end
if write_fover
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'fover',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','decay factor for surface runoff');
    netcdf.putAtt(ncid_out,ivar-1,'unites','[0-1]');
end
% if write_fmax
%     ivar = ivar + 1;
%     fover_id = netcdf.defVar(ncid_out,'fmax',fdrain_type,fdrain_dimids);
%     netcdf.putAtt(ncid_out,ivar-1,'long_name','maximum saturation fraction');
%     netcdf.putAtt(ncid_out,ivar-1,'unites','[0-1]');
% end
if write_bsw
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'bsw',fdrain_type,sand_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','bsw');
    netcdf.putAtt(ncid_out,ivar-1,'unites','-');
end
if write_sucsat
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'sucsat',fdrain_type,sand_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','ucsat');
    netcdf.putAtt(ncid_out,ivar-1,'unites','-');
end
if write_xksat
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'xksat',fdrain_type,sand_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','xksat');
    netcdf.putAtt(ncid_out,ivar-1,'unites','-');
end
if write_watsat
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'watsat',fdrain_type,sand_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','watsat');
    netcdf.putAtt(ncid_out,ivar-1,'unites','-');
end
if write_fc
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'pc',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','pc');
    netcdf.putAtt(ncid_out,ivar-1,'unites','-');
end
if write_mu
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'mu',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','mu');
    netcdf.putAtt(ncid_out,ivar-1,'unites','-');
end
if write_micro_sigma
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'micro_sigma',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','micro_sigma');
    netcdf.putAtt(ncid_out,ivar-1,'unites','-');
end
if write_kh2osfc
    ivar = ivar + 1;
    fover_id = netcdf.defVar(ncid_out,'kh2osfc',fdrain_type,fdrain_dimids);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','kh2osfc');
    netcdf.putAtt(ncid_out,ivar-1,'unites','-');
end


varid = netcdf.getConstant('GLOBAL');

[~,user_name]=system('echo $USER');
netcdf.putAtt(ncid_out,varid,'Created_by' ,user_name(1:end-1));
netcdf.putAtt(ncid_out,varid,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
netcdf.endDef(ncid_out);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% Find the nearest neighbor index for (long_region,lati_xy) within global
% dataset
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

% read in global pft mask 1=valid 0=invalid
pftmask = ncread(clm_gridded_surfdata_filename,'PFTDATA_MASK');

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Copy variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for ivar = 1:nvars
    
    %disp(varnames{ivar})
    [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
    data = netcdf.getVar(ncid_inp,ivar-1);
    switch varname
        case {'LATIXY'}
            netcdf.putVar(ncid_out,ivar-1,lati_region);
        case {'LONGXY'}
            netcdf.putVar(ncid_out,ivar-1,long_region);
        otherwise
            
            switch length(vardimids)
                case 0
                    netcdf.putVar(ncid_out,ivar-1,data);
                case 1
                    if vardimids == 0
                        netcdf.putVar(ncid_out,ivar-1,data(in));
                    else
                        data = 0;
                        netcdf.putVar(ncid_out,ivar-1,0,length(data),data);
                    end
                case 2
                    if (min(vardimids) == 0)
                        netcdf.putVar(ncid_out,ivar-1,data(in,:));
                    else
                        netcdf.putVar(ncid_out,ivar-1,data);
                    end
                case 3
                    if (min(vardimids) == 0)
                        netcdf.putVar(ncid_out,ivar-1,zeros(length(size(data(in,:,:))),1)',size(data(in,:,:)),data(in,:,:));
                    else
                        netcdf.putVar(ncid_out,ivar-1,data);
                    end
                case 4
                    if (min(vardimids) == 0)
                        netcdf.putVar(ncid_out,ivar-1,data(in,:,:,:));
                    else
                        netcdf.putVar(ncid_out,ivar-1,data);
                    end
                otherwise
                    disp('error')
            end
    end
end

if write_fdrain
    ivar = nvars + 1;
    netcdf.putVar(ncid_out,ivar-1,fdrain);
end
if write_max_drain
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,max_drain);
end
if write_ice_imped
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,ice_imped);
end
if write_snoalb_factor
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,snoalb_factor);
end
if write_fover
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,fover);
end
% if write_fmax
%     ivar = ivar + 1;
%     netcdf.putVar(ncid_out,ivar-1,fmax);
% end
if write_bsw
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,bsw);
end
if write_sucsat
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,sucsat);
end
if write_xksat
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,xksat);
end
if write_watsat
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,watsat);
end
if write_fc
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,fc);
end
if write_mu
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,mu);
end
if write_micro_sigma
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,micro_sigma);
end
if write_kh2osfc
    ivar = ivar + 1;
    netcdf.putVar(ncid_out,ivar-1,kh2osfc);
end
% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

end

