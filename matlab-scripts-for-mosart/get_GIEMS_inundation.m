function [frac_in, frac, lon_in, lat_in, yr, mo] = get_GIEMS_inundation(S,use_ori)
    addpath('/Users/xudo627/OneDrive - PNNL/donghui/mylib/m/');
    addpath('/Users/xudo627/donghui/CODE/topotoolbox/colormaps/');
    addpath('/Users/xudo627/OneDrive - PNNL/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-for-mosart/');
    
    if nargin == 1
        use_ori = 0;
    end
    
    k = 1;
    for i = 1993 : 2007
        for j = 1 : 12
            yr(k,1) = i;
            mo(k,1) = j;
            k = k + 1;
        end
    end
        
    % load GIEMS inundation with wetland removed
    if use_ori
        alternative_giems_1993_2007 = zeros(1440,720,144);
        data = load('/Users/xudo627/DATA/GIEMS/wetland_global_extent_1993_2007_Papa_etal_2010_Prigent_etal_2012.dat');
        lat = data(:,2);
        lon = data(:,3);
        lon(lon > 180) = lon(lon > 180) - 360;
        
        in = inpolygon(lon,lat,S.X,S.Y);
        frac    = data(in,4:end);
        frac_in = data(in,4:end);
        frac_in(frac_in == -99) = NaN;
        lon_in = lon(in);
        lat_in = lat(in);
    else
        load('/Users/xudo627/DATA/GIEMS/GIEMS_1993_2007.mat');
            % load half degree cooridinates 
        latixy = ncread('/Users/xudo627/projects/cesm-inputdata/MOSART_global_half_20180721a.nc','latixy');
        longxy = ncread('/Users/xudo627/projects/cesm-inputdata/MOSART_global_half_20180721a.nc','longxy');

        [~,~,num_of_months] = size(alternative_giems_1993_2007);

        % find the index corresponding to the cells inside the given boundary
        in = inpolygon(longxy,latixy,S.X,S.Y);
        lat_in = latixy(in);
        lon_in = longxy(in);

        frac_in = NaN(sum(in(:)),num_of_months);

        for i = 1 : num_of_months
            tmp = alternative_giems_1993_2007(:,:,i);
            tmp(tmp < 0) = 0;
            tmp = fliplr(tmp);
            tmp = convert_res(tmp,1,2)./4;
            frac_in(:,i) = tmp(in);
        end
    end

    
end

