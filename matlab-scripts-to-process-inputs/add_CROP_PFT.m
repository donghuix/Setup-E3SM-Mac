function add_CROP_PFT(fname_inp,fname_out,PCT_NATVEG,PCT_CROP,PCT_NAT_PFT,PCT_CFT,...
                      MONTHLY_LAI,MONTHLY_SAI,MONTHLY_HEIGHT_TOP,MONTHLY_HEIGHT_BOT)
    
% Check if the file is available
if ~exist(fname_inp, 'file')
    error(['File not found: ' mosart_gridded_surfdata_filename]);
end
ncid_inp = netcdf.open(fname_inp,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(fname_inp);
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for idim = 1:ndims
    [dimname, dimlen] = netcdf.inqDim(ncid_inp,idim-1);
    switch dimname
        case 'gridcell'
            grid_dimid   = netcdf.defDim(ncid_out,dimname,dimlen);
        case 'lsmpft'
            dimids(idim) = netcdf.defDim(ncid_out,dimname,25);
        case 'natpft'
            dimids(idim) = netcdf.defDim(ncid_out,dimname,15);
        case 'time'
            dimids(idim) = netcdf.defDim(ncid_out,dimname,netcdf.getConstant('NC_UNLIMITED'));
        otherwise
            for ii=1:length(info_inp.Dimensions)
                if (strcmp(info_inp.Dimensions(ii).Name,dimname) == 1)
                    [dimname, dimlen] = netcdf.inqDim(ncid_inp,ii-1);
                end
            end
            dimids(idim) = netcdf.defDim(ncid_out,dimname,dimlen);
    end     
end
% Add CROP PFT dimension
cft_dimid = netcdf.defDim(ncid_out,'cft',10);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for ivar = 1:nvars
    [varname,xtype,dimid,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid);
    if strcmp(varname,'PCT_NAT_PFT')
        pct_type = xtype;
    end
    if strcmp(varname,'natpft')
        int_type = xtype;
    end
    for iatt = 1:natts
        attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
end
% Add CROP PFT attribution
varid(ivar+1) = netcdf.defVar(ncid_out,'cft',int_type,cft_dimid);
netcdf.putAtt(ncid_out,ivar,'long_name','indices of CFTs');
netcdf.putAtt(ncid_out,ivar,'unites','index');

varid(ivar+2) = netcdf.defVar(ncid_out,'PCT_CFT',pct_type,[grid_dimid cft_dimid]);
netcdf.putAtt(ncid_out,ivar+1,'long_name','percent crop functional type on the crop landunit (% of landunit)');
netcdf.putAtt(ncid_out,ivar+1,'unites','unitless');

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
    
    %disp(varnames{ivar})
    [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
    data = netcdf.getVar(ncid_inp,ivar-1);
    switch varname
        case 'natpft'
            data = [0:14]';
        case 'PCT_NATVEG'
            data = PCT_NATVEG;
        case 'PCT_CROP'
            data = PCT_CROP;
        case 'PCT_NAT_PFT'
            data = PCT_NAT_PFT;
        case 'MONTHLY_LAI'
            data = MONTHLY_LAI;
        case 'MONTHLY_SAI'
            data = MONTHLY_SAI;
        case 'MONTHLY_HEIGHT_TOP'
            data = MONTHLY_HEIGHT_TOP;
        case 'MONTHLY_HEIGHT_BOT'
            data = MONTHLY_HEIGHT_BOT;
    end
    
    if  length(vardimids) == 3
        netcdf.putVar(ncid_out,ivar-1,zeros(1,length(size(data))),size(data),data);
    else
        netcdf.putVar(ncid_out,ivar-1,data);
    end
end
ivar = ivar + 1;
netcdf.putVar(ncid_out,ivar-1,[0:9]');
ivar = ivar + 1;
netcdf.putVar(ncid_out,ivar-1,PCT_CFT);
% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

end

