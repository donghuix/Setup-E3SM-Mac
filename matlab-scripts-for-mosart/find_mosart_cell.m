% ####################################################################### %
% Description: search the contribuing grid cells in the MOSART domain given
%              the coordinate of a station 
%
% Input:  fname -> file name of MOSART domain file
%         lon ---> longitude of the station
%         lat ---> latitude of the station
% Output: ioutlet -------> corresponding outlet index in the domain file
%         icontributing -> the indices of the cells that contributing to
%                          the given coordinate
%
%
% Author: Donghui Xu
% Date: 08/13/2020
% ####################################################################### %
function [ioutlet, icontributing] = find_mosart_cell(fname,lon,lat)
    
    debug = 0;
    searching_method = 2; % method 1: searching from each cell to see if it flows to the given outlet
                          % method 2: searching from the outlet <- much quicker!
    
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
    if searching_method == 1
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
    elseif searching_method == 2
        found = outletg;
        while ~isempty(found)
            found2 = [];
            for i = 1 : length(found)
                upstrm = find(dnID == found(i));
                found2 = [found2; upstrm];
            end
            icontributing = [icontributing; found2];
            found = found2;
        end
    end
    if debug
        figure;
        plot(longxy(icontributing),latixy(icontributing),'k+'); hold on;
        plot(longxy(ioutlet), latixy(ioutlet), 'ro');
    end
end

