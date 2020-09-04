function data = read_usgs_streamflow(filename)
    fid = fopen(filename);
    C = textscan(fid,repmat('%s',1,25),'HeaderLines',44,'Delimiter','\t');
    data = C{22};
    fclose(fid);
end

