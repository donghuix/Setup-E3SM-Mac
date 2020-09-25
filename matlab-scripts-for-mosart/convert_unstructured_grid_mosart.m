clear;close all;clc;

fname_in  = '/Users/xudo627/projects/cesm-inputdata/MOSART_Global_half_20200720.nc';
fname_out = ['/Users/xudo627/projects/cesm-inputdata/MOSART_Global_half_unstructured_' ...
             datestr(now, 'cyymmdd') '.nc'];

ncid_inp = netcdf.open(fname_in,   'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(fname_in);
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

% read original dimension
[~, latlen] = netcdf.inqDim(ncid_inp,8);
[~, lonlen] = netcdf.inqDim(ncid_inp,9);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1) = netcdf.defDim(ncid_out,'gridcell',latlen*lonlen);
dimid(2) = netcdf.defDim(ncid_out,'nele',11);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
k = 1;
for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    switch varname
        case {'ele0','ele1','ele2','ele3','ele4','ele5','ele6','ele7',...
              'ele8','ele9','ele10'}
            continue;
        case {'ele'}
            varnames{k} = varname;
            varid(k) = netcdf.defVar(ncid_out,varname,xtype,[dimid(1),dimid(2)]);
            for iatt = 1 : natts
                attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
                attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);

                netcdf.putAtt(ncid_out,k-1,attname,attvalue);
            end
            k = k + 1;
        otherwise
            varnames{k} = varname;
            varid(k) = netcdf.defVar(ncid_out,varname,xtype,[dimid(1)]);
            for iatt = 1 : natts
                attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
                attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);

                netcdf.putAtt(ncid_out,k-1,attname,attvalue);
            end
            k = k + 1;
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
k = 1;
for ivar = 1:nvars
    [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
    data = netcdf.getVar(ncid_inp,ivar-1);
    switch varname
        case {'ele0','ele1','ele2','ele3','ele4','ele5','ele6','ele7',...
              'ele8','ele9','ele10'}
            continue;
        case {'lat'}
            data = ncread(fname_in,'latixy');
            netcdf.putVar(ncid_out,ivar-1,data(:));
            k = k + 1;
        case {'lon'}
            data = ncread(fname_in,'longxy');
            netcdf.putVar(ncid_out,k-1,data(:));
            k = k + 1;
        case {'ele'}
            ele = zeros(latlen*lonlen,11);
            for iele = 1 : 11
                ele1 = data(:,:,iele);
                ele(:,iele) = ele1(:);
            end
            netcdf.putVar(ncid_out,k-1,ele);
            k = k + 1;
        otherwise
            netcdf.putVar(ncid_out,k-1,data(:));
            k = k + 1;
    end
end

% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

