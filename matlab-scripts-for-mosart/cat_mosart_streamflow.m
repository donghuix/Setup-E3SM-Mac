% ####################################################################### %
% files: files for MOSART output files
% fname: MOSART input file
% lons, lats: coordinates for point of interest
% areas: contributing area [m^2]
% run_parallel: if read the data in parallel, default is inactive
%
% SFTS: StreamFlow Time Series
%
% Author: Donghui Xu
% Date: 11/03/2021
% ####################################################################### %
function SFTS = cat_mosart_streamflow(files,fname,lons,lats,areas,run_parallel)

    if nargin == 5
        run_parallel = 0;
    end

    % Search for the grid cell index for the point of interest
    for i = 1 : length(lons)
        if isempty(areas)
            ioutlets(i) = find_mosart_cell(fname,lons(i),lats(i),[]);
        else
            ioutlets(i) = find_mosart_cell(fname,lons(i),lats(i),areas(i));
        end
    end

    % Read streamflow from the outputs
    SFTS = NaN(length(lons),length(files));
    if run_parallel
        % TODO: add parallel process 
        for i = 1 : length(files)
            filename = fullfile(files(i).folder,files(i).name);
            RDL = ncread(filename,'RIVER_DISCHARGE_OVER_LAND_LIQ');
            RDO = ncread(filename,'RIVER_DISCHARGE_TO_OCEAN_LIQ');
            for j = 1 : length(lons)
                if isnan(RDL(ioutlets(j)))
                    SFTS(j,i) = RDO(ioutlets(j));
                else
                    SFTS(j,i) = RDL(ioutlets(j));
                end
            end
        end
    else
        for i = 1 : length(files)
            filename = fullfile(files(i).folder,files(i).name);
            RDL = ncread(filename,'RIVER_DISCHARGE_OVER_LAND_LIQ');
            RDO = ncread(filename,'RIVER_DISCHARGE_TO_OCEAN_LIQ');
            for j = 1 : length(lons)
                if isnan(RDL(ioutlets(j)))
                    SFTS(j,i) = RDO(ioutlets(j));
                else
                    SFTS(j,i) = RDL(ioutlets(j));
                end
            end
        end
    end
end

