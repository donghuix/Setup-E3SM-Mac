function [frac_in, lon_in, lat_in, yr, mo] = get_GIEMS_inundation(S)
    addpath('/Users/xudo627/OneDrive - PNNL/donghui/mylib/m/');
    addpath('/Users/xudo627/projects/topotoolbox/colormaps/');
    addpath('/Users/xudo627/OneDrive - PNNL/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-for-mosart/');
    
    % load GIEMS inundation with wetland removed
    load('/Users/xudo627/DATA/GIEMS_1993_2007.mat');
    % load half degree cooridinates 
    latixy = ncread('/Users/xudo627/projects/cesm-inputdata/MOSART_global_half_20180721a.nc','latixy');
    longxy = ncread('/Users/xudo627/projects/cesm-inputdata/MOSART_global_half_20180721a.nc','longxy');
    
    [~,~,num_of_months] = size(alternative_giems_1993_2007);
    
    % find the index corresponding to the cells inside the given boundary
    in = inpolygon(longxy,latixy,S.X,S.Y);
    lat_in = latixy(in);
    lon_in = longxy(in);
    
    k = 1;
    for i = 1993 : 2007
        for j = 1 : 12
            yr(k,1) = i;
            mo(k,1) = j;
            k = k + 1;
        end
    end
    
    frac_in = NaN(sum(in(:)),num_of_months);
    
    for i = 1 : num_of_months
        tmp = alternative_giems_1993_2007(:,:,i);
        tmp(tmp < 0) = 0;
        tmp = convert_res(tmp,1,2)./4;
        frac_in(:,i) = tmp(in);
    end
    
end

