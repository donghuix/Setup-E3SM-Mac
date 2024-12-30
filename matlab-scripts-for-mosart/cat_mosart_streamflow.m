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
function [SFTS,ioutlets] = cat_mosart_streamflow(files,fname,lons,lats,areas,ioutlets,run_parallel)

    if nargin == 6
        run_parallel = 0;
    end

    % Search for the grid cell index for the point of interest
    if isempty(ioutlets)
        for i = 1 : length(lons)
            if isempty(areas)
                [ioutlets(i),icontri{i}] = find_mosart_cell(fname,lons(i),lats(i),[]);
            else
                [ioutlets(i),icontri{i}] = find_mosart_cell(fname,lons(i),lats(i),areas(i));
            end
        end
    end
    area = ncread(fname,'area');
    
    tenperc = ceil(0.1*length(files));
    fprintf('\n------------ Reading MOSART outputs------------\n\n');
    % Determine if FLOODPLAIN_FRACTION exists in the outputs
    filename = fullfile(files(1).folder,files(1).name);
    ncid = netcdf.open(filename,'nowrite');
    try 
        read_inundation = true;
        FP = netcdf.inqVarID(ncid,'FLOODPLAIN_FRACTION');
    catch exception
        read_inundation = false;
    end
    netcdf.close(ncid);
    % Read streamflow from the outputs
    if read_inundation
        SFTS = NaN(length(lons),length(files),2);
    else
        SFTS = NaN(length(lons),length(files));
    end
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
            if mod(i,tenperc) == 0
                fprintf(['.' num2str(i/tenperc*10) '%%']);
            end
            RDL = ncread(filename,'RIVER_DISCHARGE_OVER_LAND_LIQ');
            RDO = ncread(filename,'RIVER_DISCHARGE_TO_OCEAN_LIQ');
            for j = 1 : length(lons)
                if isnan(RDL(ioutlets(j)))
                    SFTS(j,i,1) = RDO(ioutlets(j));
                else
                    SFTS(j,i,1) = RDL(ioutlets(j));
                end
            end
            if read_inundation
                FP  = ncread(filename,'FLOODPLAIN_FRACTION');
                for j = 1 : length(lons)
                    SFTS(j,i,2) = nansum(FP([ioutlets(j); icontri{j}]).*area([ioutlets(j); icontri{j}]));
                end
            end
        end
        fprintf('.100%% Done!\n');
        fprintf('\n-----------------------------------------------\n\n');
    end
end

