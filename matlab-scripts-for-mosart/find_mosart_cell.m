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
function [ioutlet, icontributing] = find_mosart_cell(fname,lon,lat,target_area)
       
    debug = 0;
    searching_method = 2; % method 1: searching from each cell to see if it flows to the given outlet
                          % method 2: searching from the outlet <- much quicker!
    
    if nargin == 3
        target_area = [];
    end
    
    dnID = ncread(fname,'dnID');
    ID   = ncread(fname,'ID');
    latixy = ncread(fname,'latixy');
    longxy = ncread(fname,'longxy');
    area   = ncread(fname,'area');
    
    if ~isempty(target_area)
        if target_area < nanmean(area)
            disp('watershed is smaller than the grid cell!!!');
            target_area = [];
        end
    end
    
    [m,n] = size(dnID);
    num_of_cells = m * n;
    
    dist = pdist2([longxy(:) latixy(:)],[lon lat]);
    [B,I] = sort(dist);
    
    if isempty(target_area)
        search_N = 1;
    else
        search_N = 20;
    end
    
    for ifound = 1 : search_N
        ioutlet = I(ifound);
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
        if ~isempty(target_area)
            drainage_area = nansum(area([ioutlet; icontributing]));
            %disp(drainage_area/2.59e+6);
            if drainage_area/target_area > 0.5 && drainage_area/target_area < 1.5
                fprintf(['MOSART drainage area is ' num2str(drainage_area/1e6) 'km^{2}\n']);
                fprintf(['GSIM drainage area is ' num2str(target_area/1e6) 'km^{2}\n']);
                break;
            end
        end
    end
    if ~isempty(target_area)
        if drainage_area/target_area < 0.5 || drainage_area/target_area > 1.5
            ioutlet = I(1);
            outletg = ID(ioutlet);
            icontributing = [];
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
    end
    if debug
        figure;
        plot(longxy(icontributing),latixy(icontributing),'k+'); hold on;
        plot(longxy(ioutlet), latixy(ioutlet), 'ro');
    end
end

