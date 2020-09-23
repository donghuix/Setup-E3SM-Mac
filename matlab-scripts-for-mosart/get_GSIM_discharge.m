function [lon,lat,yr,mo,da,mu,sd,cv] = get_GSIM_discharge(station)

    filename = fullfile('/Users/xudo627/DATA/GSIM_indices/TIMESERIES/monthly',strcat(station,'.mon'));
    fid = fopen(filename);
    C = textscan(fid,'%s%s%s%s%s%s%s%s%s%d%d','HeaderLines',22,'Delimiter',',');
    fclose(fid);
    D  = C{1};
    M = C{2};
    S = C{3};
    V = C{4};
    
    yr = NaN(length(D),1);
    mo = NaN(length(D),1);
    da = NaN(length(D),1);
    mu = NaN(length(D),1);
    sd = NaN(length(D),1);
    cv = NaN(length(D),1);
    
    for i = 1 : length(D)
        strs = strsplit(D{i},'-');
        yr(i) = str2double(strs{1});
        mo(i) = str2double(strs{2});
        da(i) = str2double(strs{3});
        if strcmp(M{i}, 'NA')
            mu(i) = NaN;
            sd(i) = NaN;
            cv(i) = NaN;
        else
            mu(i) = str2double(M{i});
            sd(i) = str2double(S{i});
            cv(i) = str2double(V{i});
        end
    end
    
    fid = fopen(filename);
    tline = fgetl(fid);
    while ischar(tline)
        if contains(tline,'latitude')
            strs = strsplit(tline,':');
            lat  = str2double(strs{2});
        elseif contains(tline,'longitude')
            strs = strsplit(tline,':');
            lon  = str2double(strs{2});
        end
        tline = fgetl(fid);
    end
    
end