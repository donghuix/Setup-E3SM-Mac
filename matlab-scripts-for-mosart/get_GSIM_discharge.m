function [lon,lat,Sh,yr,mo,da,mu,sd,cv] = get_GSIM_discharge(station,read_boundary)

    if nargin == 1
        read_boundary = 0;
        Sh = [];
    end
    
    if read_boundary == 2
        Sh = struct([]);
        addpath('/Users/xudo627/donghui/CODE/m_map/');
        fname = ['/Users/xudo627/DATA/GSIM_metadata/GSIM_catchments/' station];
        M=m_shaperead(fname);
        Sh(1).X = M.ncst(:,1);
        Sh(2).Y = M.ncst(:,2);
    elseif read_boundary == 1
        Sh = shaperead(['/Users/xudo627/DATA/GSIM_metadata/GSIM_catchments/' station '.shp']);
    end
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