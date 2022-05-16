function generate_mapping(fname,domain_a,domain_b,in,method)
    
    debug = 1;
    
    xc_a = ncread(domain_a,'xc'); xc_a(xc_a > 180) = xc_a(xc_a > 180) - 360;
    yc_a = ncread(domain_a,'yc');
    xv_a = ncread(domain_a,'xv');
    yv_a = ncread(domain_a,'yv');
    mask_a = ncread(domain_a,'mask');
    area_a = ncread(domain_a,'area');
    frac_a = ncread(domain_a,'frac');

    xc_b = ncread(domain_b,'xc');
    yc_b = ncread(domain_b,'yc');
    xv_b = ncread(domain_b,'xv');
    yv_b = ncread(domain_b,'yv');
    mask_b = ncread(domain_b,'mask');
    area_b = ncread(domain_b,'area');
    frac_b = ncread(domain_b,'frac');
    
    n_a = length(xc_a);
    ni_a = n_a;
    nj_a = 1;
    nv_a = size(xv_a,1);
    src_grid_rank = 2;
    
    n_b = length(xc_b(:));
    [ni_b, nj_b] = size(xc_b);
    nv_b = size(xv_b,1);
    dst_grid_rank = 2;
    
    ncid = netcdf.create(fname,'NETCDF4');
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    dimid(1) = netcdf.defDim(ncid,'n_a',  n_a);
    dimid(2) = netcdf.defDim(ncid,'ni_a', ni_a);
    dimid(3) = netcdf.defDim(ncid,'nj_a', nj_a);
    dimid(4) = netcdf.defDim(ncid,'nv_a', nv_a);
    dimid(5) = netcdf.defDim(ncid,'src_grid_rank', src_grid_rank);
    dimid(6) = netcdf.defDim(ncid,'n_b',  n_b);
    dimid(7) = netcdf.defDim(ncid,'ni_b', ni_b);
    dimid(8) = netcdf.defDim(ncid,'nj_b', nj_b);
    dimid(9) = netcdf.defDim(ncid,'nv_b', nv_b);
    dimid(10)= netcdf.defDim(ncid,'dst_grid_rank', dst_grid_rank);
    dimid(11)= netcdf.defDim(ncid,'n_s', n_b);
    
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
    
    % Source 
    varid(1) = netcdf.defVar(ncid,'xc_a','NC_DOUBLE',[dimid(1)]); 
    netcdf.putAtt(ncid,1-1,'long_name','longitude of grid cell center (input)');
    netcdf.putAtt(ncid,1-1,'units','degrees east');
    
    varid(2) = netcdf.defVar(ncid,'yc_a','NC_DOUBLE',[dimid(1)]); 
    netcdf.putAtt(ncid,2-1,'long_name','latitude of grid cell center (input)');
    netcdf.putAtt(ncid,2-1,'units','degrees north');
    
    varid(3) = netcdf.defVar(ncid,'xv_a','NC_DOUBLE',[dimid(4) dimid(1)]); 
    netcdf.putAtt(ncid,3-1,'long_name','longitude of grid cell verticies (input)');
    netcdf.putAtt(ncid,3-1,'units','degrees east');
    
    varid(4) = netcdf.defVar(ncid,'yv_a','NC_DOUBLE',[dimid(4) dimid(1)]); 
    netcdf.putAtt(ncid,4-1,'long_name','latitude of grid cell verticies (input)');
    netcdf.putAtt(ncid,4-1,'units','degrees north');
    
    varid(5) = netcdf.defVar(ncid,'mask_a','NC_INT',[dimid(1)]); 
    netcdf.putAtt(ncid,5-1,'long_name','domain mask (input)');
    
    varid(6) = netcdf.defVar(ncid,'area_a','NC_DOUBLE',[dimid(1)]); 
    netcdf.putAtt(ncid,6-1,'long_name','area of cell (input)');
    
    varid(7) = netcdf.defVar(ncid,'frac_a','NC_DOUBLE',[dimid(1)]); 
    netcdf.putAtt(ncid,7-1,'long_name','fraction of domain intersection (input)');
    
    varid(8) = netcdf.defVar(ncid,'src_grid_dims','NC_INT',[dimid(5)]); 
    
    % Destination
    varid(9) = netcdf.defVar(ncid,'xc_b','NC_DOUBLE',[dimid(6)]); 
    netcdf.putAtt(ncid,9-1,'long_name','longitude of grid cell center (input)');
    netcdf.putAtt(ncid,9-1,'units','degrees east');
    
    varid(10) = netcdf.defVar(ncid,'yc_b','NC_DOUBLE',[dimid(6)]); 
    netcdf.putAtt(ncid,10-1,'long_name','latitude of grid cell center (input)');
    netcdf.putAtt(ncid,10-1,'units','degrees north');
    
    varid(11) = netcdf.defVar(ncid,'xv_b','NC_DOUBLE',[dimid(9) dimid(6)]); 
    netcdf.putAtt(ncid,11-1,'long_name','longitude of grid cell verticies (input)');
    netcdf.putAtt(ncid,11-1,'units','degrees east');
    
    varid(12) = netcdf.defVar(ncid,'yv_b','NC_DOUBLE',[dimid(9) dimid(6)]); 
    netcdf.putAtt(ncid,12-1,'long_name','latitude of grid cell verticies (input)');
    netcdf.putAtt(ncid,12-1,'units','degrees north');
    
    varid(13) = netcdf.defVar(ncid,'mask_b','NC_INT',[dimid(6)]); 
    netcdf.putAtt(ncid,13-1,'long_name','domain mask (input)');
    
    varid(14) = netcdf.defVar(ncid,'area_b','NC_DOUBLE',[dimid(6)]); 
    netcdf.putAtt(ncid,14-1,'long_name','area of cell (input)');
    
    varid(15) = netcdf.defVar(ncid,'frac_b','NC_DOUBLE',[dimid(6)]); 
    netcdf.putAtt(ncid,15-1,'long_name','fraction of domain intersection (input)');
    
    varid(16) = netcdf.defVar(ncid,'dst_grid_dims','NC_INT',[dimid(10)]); 
    
    % Sparse matrix for interpolation
    varid(17) = netcdf.defVar(ncid,'S','NC_DOUBLE',[dimid(11)]); 
    netcdf.putAtt(ncid,17-1,'long_name','sparse matrix for mapping S:a->b');
    
    varid(18) = netcdf.defVar(ncid,'col','NC_INT',[dimid(11)]); 
    netcdf.putAtt(ncid,18-1,'long_name','column corresponding to matrix elements');
    
    varid(19) = netcdf.defVar(ncid,'row','NC_INT',[dimid(11)]); 
    netcdf.putAtt(ncid,19-1,'long_name','row corresponding to matrix elements');
    
    varid = netcdf.getConstant('GLOBAL');

    [~,user_name]=system('echo $USER');
    netcdf.putAtt(ncid,varid,'Created_by' ,user_name(1:end-1));
    netcdf.putAtt(ncid,varid,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
    netcdf.endDef(ncid);
    
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Copy variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
    
    for i = 1 : nv_a
        tmp = xv_a(i,:,:);
        xv_a2(i,:) = tmp(:);
        tmp = yv_a(i,:,:);
        yv_a2(i,:) = tmp(:);
    end
    for i = 1 : nv_b
        tmp = xv_b(i,:,:);
        xv_b2(i,:) = tmp(:);
        tmp = yv_b(i,:,:);
        yv_b2(i,:) = tmp(:);
    end
    netcdf.putVar(ncid,1-1,xc_a(:));
    netcdf.putVar(ncid,2-1,yc_a(:));
    netcdf.putVar(ncid,3-1,xv_a2);
    netcdf.putVar(ncid,4-1,yv_a2);
    netcdf.putVar(ncid,5-1,mask_a(:));
    netcdf.putVar(ncid,6-1,area_a(:));
    netcdf.putVar(ncid,7-1,frac_a(:));
    netcdf.putVar(ncid,8-1,[ni_a; nj_a]);
    
    netcdf.putVar(ncid,9-1,xc_b(:));
    netcdf.putVar(ncid,10-1,yc_b(:));
    netcdf.putVar(ncid,11-1,xv_b2);
    netcdf.putVar(ncid,12-1,yv_b2);
    netcdf.putVar(ncid,13-1,mask_b(:));
    netcdf.putVar(ncid,14-1,area_b(:));
    netcdf.putVar(ncid,15-1,frac_b(:));
    netcdf.putVar(ncid,16-1,[ni_b; nj_b]);
    
    xc_a = xc_a(:); yc_a = yc_a(:);
    xc_b = xc_b(:); yc_b = yc_b(:);
    
    if strcmp(method,'nearest')
        S   = zeros(n_b,1);
        col = NaN(n_b,1);
        row = NaN(n_b,1);
        for i = 1 : n_b
            if in(i) == 1
                dist = sqrt((xc_a - xc_b(i)).^2 + (yc_a - yc_b(i)).^2);
                ind  = find(dist == min(dist));
                S(i) = 1;
                col(i) = ind;
            else
                col(i) = 1;
            end
            row(i) = i;
        end
    else
        error([method ' is not supported']);
    end
    
    netcdf.putVar(ncid,17-1,S);
    netcdf.putVar(ncid,18-1,col);
    netcdf.putVar(ncid,19-1,row);
    
    netcdf.close(ncid);
    
    if debug == 1
        for i = 1 : n_b
            if in(i) == 1
                plot([xc_a(col(i)) xc_b(i)],[yc_a(col(i)) yc_b(i)],'b-','LineWidth',1); hold on;
            end
        end
    end
end

