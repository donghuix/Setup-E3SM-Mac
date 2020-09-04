function [data, yr, mo, da] = read_usgs_streamflow(filename)
    fid = fopen(filename);
    C = textscan(fid,repmat('%s',1,25),'HeaderLines',44,'Delimiter','\t');
    data = C{22};
    data = str2double(data);
    D    = C{3};
    fclose(fid);
    for i = 1 : length(data)
        strs = strsplit(D{i},'-');
        yr(i,1) = str2num(strs{1});
        mo(i,1) = str2num(strs{2});
        da(i,1) = str2num(strs{3});
    end
end

