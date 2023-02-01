function [rwid,rdep,flood_2yr] = get_geometry(xc,yc,ID,dnID,area,aw,ad)
    lon = -179.75:0.5:179.75;
    lat = -59.75:0.5:89.75;
    [lon,lat] = meshgrid(lon,lat);
    lon = lon';
    lat = lat';
    
    if nargin == 5
        aw = 7.2;
        ad = 0.27;
    elseif isempty(aw) || isempty(ad)
        aw = 7.2;
        ad = 0.27;
    end
    
    runoff    = NaN(length(xc),31*365);
    discharge = NaN(length(xc),31*365);
    AMF       = NaN(length(xc),31);
    k = 1;
    fprintf('Generating nearest neighbour mapping...\n');
    inear = NaN(length(xc),1);
    onepercent = floor(length(xc) / 100);
    for i = 1 : length(xc)
        if mod(i,onepercent) == 0
            fprintf([' ' num2str(i/onepercent) '% ']);
        elseif i == length(xc)
            fprintf(' 100% \n');
        end
        dist = sqrt((lon - xc(i)).^2 + (lat - yc(i)).^2);
        %find(dist == min(dist(:)))
        ind  = find(dist == min(dist(:)));
        if isempty(ind)
            error('Cannot find nearest neighbour!');
        elseif length(ind) > 1
            disp([num2str(length(ind)) ' grid cells are found!']);
            disp('*** Warning: This first one is used. ***');
            ind = ind(1);
        end
        inear(i) = ind;
    end
    
    fprintf('Reading daily runoff...\n');
    for i = 1979 : 2009
        if mod(i-1979+1,10) == 0
            fprintf(['Year ' num2str(i) '\n']);
        else
            fprintf(['Year ' num2str(i)]);
        end
        for j = 1 : 365
            load(['/Users/xudo627/DATA/Runoff/runoff/RUNOFF05_' num2str(i) '_' num2str(j) '.mat']);
            runoff(:,k) = ro05(inear);
            k = k + 1;
        end
    end
    
    in = cell(length(xc),1);
    fprintf('Searching for contribuing area...\n');
    for i = 1 : length(xc)
        if mod(i,onepercent) == 0
            fprintf([' ' num2str(i/onepercent) '% ']);
        elseif i == length(xc)
            fprintf(' 100% \n');
        end
        [ioutlet, icontributing] = find_contributing_cells(xc,yc,ID,dnID,area, ...
                                                           xc(i),yc(i));
        in{i} = [ioutlet; icontributing];
    end
    
    fprintf('Mapping runoff to discharge...\n');
    for i = 1 : length(xc)
        if mod(i,onepercent) == 0
            fprintf([' ' num2str(i/onepercent) '% ']);
        elseif i == length(xc)
            fprintf(' 100% \n');
        end
        discharge(i,:) = nansum(runoff(in{i},:) .* area(in{i}) ./1000./(3*60*60),1);
    end
    for i = 1 : 31
        tmp = discharge(:,(i-1)*365+1 : i*365);
        AMF(:,i) = max(tmp,[],2);
    end
    flood_2yr = prctile(AMF,50,2);
    
    rwid = aw.*flood_2yr.^0.52;
    rdep = ad.*flood_2yr.^0.31;
end

function [ioutlet, icontributing] = find_contributing_cells(longxy,latixy,ID,dnID,area, ...
                                                     lon,lat,target_area)
       
    debug = 0;
    searching_method = 2; % method 1: searching from each cell to see if it flows to the given outlet
                          % method 2: searching from the outlet <- much quicker!
    
    if nargin == 7
        target_area = [];
    end
    
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


