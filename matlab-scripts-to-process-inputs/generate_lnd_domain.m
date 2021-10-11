function area = generate_lnd_domain(xc,yc,xv,yv,frac,mask,area,fname_out)

[ni,nj] = size(xc);
if ni == 1 && nj > 1
    error('Unstructured data, need to use column vector!')
end
nv  = size(xv,1);
n = ni * nj;

ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

dimid(1) = netcdf.defDim(ncid_out,'n',n);
dimid(2) = netcdf.defDim(ncid_out,'ni',ni);
dimid(3) = netcdf.defDim(ncid_out,'nj',nj);
dimid(4) = netcdf.defDim(ncid_out,'nv',nv);


% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
varnames = {'xc', 'yc', 'xv', 'yv', 'mask', 'area', 'frac'};
nvars = length(varnames);
ivar = 1;
varid(1) = netcdf.defVar(ncid_out,'xc',6,[dimid(2),dimid(3)]); 
netcdf.putAtt(ncid_out,ivar-1,'long_name','longitude of grid cell center');
netcdf.putAtt(ncid_out,ivar-1,'units','degrees_east');
netcdf.putAtt(ncid_out,ivar-1,'bounds','xv');

ivar = 2;
varid(2) = netcdf.defVar(ncid_out,'yc',6,[dimid(2),dimid(3)]); 
netcdf.putAtt(ncid_out,ivar-1,'long_name','latitude of grid cell center');
netcdf.putAtt(ncid_out,ivar-1,'units','degrees_north');
netcdf.putAtt(ncid_out,ivar-1,'bounds','yv');

ivar = 3;
varid(3) = netcdf.defVar(ncid_out,'xv',6,[dimid(4),dimid(2),dimid(3)]); 
netcdf.putAtt(ncid_out,ivar-1,'long_name','longitude of grid cell verticies');
netcdf.putAtt(ncid_out,ivar-1,'units','degrees_east');

ivar = 4;
varid(4) = netcdf.defVar(ncid_out,'yv',6,[dimid(4),dimid(2),dimid(3)]); 
netcdf.putAtt(ncid_out,ivar-1,'long_name','latitude of grid cell verticies');
netcdf.putAtt(ncid_out,ivar-1,'units','degrees_north');

ivar = 5;
varid(5) = netcdf.defVar(ncid_out,'mask',4,[dimid(2),dimid(3)]); 
netcdf.putAtt(ncid_out,ivar-1,'long_name','domain mask');
netcdf.putAtt(ncid_out,ivar-1,'note','unitless');
netcdf.putAtt(ncid_out,ivar-1,'coordinates','xc yc');
netcdf.putAtt(ncid_out,ivar-1,'comment','0 value indicates cell is not active');

ivar = 6;
varid(6) = netcdf.defVar(ncid_out,'area',6,[dimid(2),dimid(3)]); 
netcdf.putAtt(ncid_out,ivar-1,'long_name','area of grid cell in radians squared');
netcdf.putAtt(ncid_out,ivar-1,'coordixnates','xc yc');
netcdf.putAtt(ncid_out,ivar-1,'units','radian2');

ivar = 7;
varid(7) = netcdf.defVar(ncid_out,'frac',6,[dimid(2),dimid(3)]); 
netcdf.putAtt(ncid_out,ivar-1,'long_name','fraction of grid cell that is active');
netcdf.putAtt(ncid_out,ivar-1,'coordixnates','xc yc');
netcdf.putAtt(ncid_out,ivar-1,'note','unitless');
netcdf.putAtt(ncid_out,ivar-1,'filter1','error if frac> 1.0+eps or frac < 0.0-eps; eps = 0.1000000E-11');
netcdf.putAtt(ncid_out,ivar-1,'filter2','limit frac to [fminval,fmaxval]; fminval= 0.1000000E-02 fmaxval=  1.000000');

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

% compute are based on vertex
ndimv = length(size(xv));
if isempty(area)
    area = zeros(ni,nj);
    for i = 1 : ni
        for j = 1 : nj
            if ndimv == 2 && nj == 1
                xv1 = xv(:,i);
                yv1 = yv(:,i);
            elseif ndimv == 3
                xv1 = xv(:,i,j);
                yv1 = yv(:,i,j);
                xv1 = xv1(:);
                yv1 = yv1(:);
            end
            area(i,j) = areaint(yv1,xv1)*4*pi; 
        end
    end
end

ivar = 1;
netcdf.putVar(ncid_out,ivar-1,xc);
ivar = 2;
netcdf.putVar(ncid_out,ivar-1,yc);
ivar = 3;
netcdf.putVar(ncid_out,ivar-1,xv);
ivar = 4;
netcdf.putVar(ncid_out,ivar-1,yv);
ivar = 5;
netcdf.putVar(ncid_out,ivar-1,mask);
ivar = 6;
netcdf.putVar(ncid_out,ivar-1,area);
ivar = 7;
netcdf.putVar(ncid_out,ivar-1,frac);

netcdf.close(ncid_out);

end

