function [ioutlet, icontributing] = find_mosart_cell(fname,lon,lat)
    
    debug = 0;
    
    dnID = ncread(fname,'dnID');
    ID   = ncread(fname,'ID');
    latixy = ncread(fname,'latixy');
    longxy = ncread(fname,'longxy');
    
    [m,n] = size(dnID);
    num_of_cells = m * n;
    
    dist = pdist2([longxy(:) latixy(:)],[lon lat]);
    [B,I] = sort(dist);
    % Assume the closest grid cell is the station point we are looking for
    % TODO: compare to the drainage area to find the outlet with similar drainage area
    ioutlet = I(1);
    outletg = ID(ioutlet);
    
    icontributing = [];
    tenperc = ceil(0.1*num_of_cells);
    
    for i = 1 : num_of_cells
        if mod(i,tenperc) == 0
            fprintf(['-' num2str(i/tenperc*10) '%%']);
        end
        found = dnID(i) == ID(outletg);
        j = i;
        while ~found && dnID(j) ~= -9999
            j = find(ID == dnID(j));
            found = dnID(j) == ID(outletg);
        end
        if found
            icontributing = [icontributing; i];
        end
    end
    fprintf('-100%% Done!\n');
    if debug
        figure;
        plot(longxy(icontributing),latixy(icontributing),'k+'); hold on;
        plot(longxy(ioutlet), latixy(ioutlet), 'ro');
    end
end

