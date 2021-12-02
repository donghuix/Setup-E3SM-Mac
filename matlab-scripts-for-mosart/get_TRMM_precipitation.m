function [TRMMin, yr, mo, xc, yc, xv, yv] = get_TRMM_precipitation(S)

    load('/Users/xudo627/DATA/TRMM/TRMMmon.mat');
    in = inpolygon(lon,lat,S.X,S.Y);
    
    dx = 1/4;
    dy = 1/4;
    
    [m,n,l] = size(TRMMmon);
    
    xv = NaN(4,sum(in(:)));
    yv = NaN(4,sum(in(:)));
    TRMMin = NaN(sum(in(:)),l);
    
    for i = 1 : l
        tmp = TRMMmon(:,:,i);
        TRMMin(:,i) = tmp(in);
    end
    xc = lon(in);
    yc = lat(in);
    
    xv(1,:) = xc - dx/2; xv(2,:) = xc + dx/2; xv(3,:) = xc + dx/2; xv(4,:) = xc - dx/2;
    yv(1,:) = yc - dy/2; yv(2,:) = yc - dy/2; yv(3,:) = yc + dy/2; yv(4,:) = yc + dy/2;
    
    [yr,mo] = datevec(tmon);
    
end