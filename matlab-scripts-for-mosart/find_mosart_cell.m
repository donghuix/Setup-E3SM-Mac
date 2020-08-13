function [ioutlet, ind] = find_mosart_cell(fname,lon,lat)
    latixy = double(ncread(filename,'lat'));
    longxy = double(ncread(filename,'lon'));
    outletg= ncread(filename,'OUTLETG');
    gindex = ncread(filename,'GINDEX');
    
    dist = pdist2([longxy latixy],[lon lat]);
    [B,I] = sort(dist);
    % Assume the closest grid cell is the station point we are looking for
    % TODO: compare to the drainage area to find the outlet with similar drainage area
    ioutlet = I(1);
    ind = find(outletg == gindex(ioutlet));
end

