function [NSE,R2] = val_mosart_streamflow(files,fname,yr1,yr2,user_basin_streamflow,show_plot,run_parallel)
    
if nargin == 5
    run_parallel = 0;
end
if nargin == 4
    show_plot    = 0;
    run_parallel = 0;
end

if isempty(user_basin_streamflow)
    load('global_basin_streamflow.mat','global_basin_streamflow');
    lons = [global_basin_streamflow(:).lon];
    lats = [global_basin_streamflow(:).lat];
    areas= [global_basin_streamflow(:).aream2];
    basin_streamflow = global_basin_streamflow;
else
    lons = [user_basin_streamflow(:).lon];
    lats = [user_basin_streamflow(:).lat];
    areas= [user_basin_streamflow(:).aream2];
    basin_streamflow = user_basin_streamflow;
end

SFTS = cat_mosart_streamflow(files,fname,lons,lats,areas,run_parallel);

NSE = NaN(length(lons),1);
R2  = NaN(length(lons),1);

yr_mos = NaN((yr2-yr1+1)*12,1);
k = 1;
for i = yr1 : yr2
    for j = 1 : 12
        yr_mos(k) = i;
        k = k + 1;
    end
end

for i = 1 : length(basin_streamflow)
    yr3 = min(basin_streamflow(i).yr);
    yr4 = max(basin_streamflow(i).yr);
    if yr3 >= yr1
        i1 = min(find(yr_mos == yr3));
        j1 = 1;
    else
        i1 = 1;
        j1 = min(find(basin_streamflow(i).yr == yr1));
    end
    if yr4 >= yr2
        i2 = length(yr_mos);
        j2 = max(find(basin_streamflow(i).yr == yr2));
    else
        i2 = max(find(yr_mos == yr4));
        j2 = length(basin_streamflow(i).mu);
    end
    [R2(i),~,NSE(i)] = estimate_evaluation_metric(basin_streamflow(i).mu(j1:j2), ...
                                                  SFTS(i,i1:i2)');
end

if show_plot
    figure;
    scatter(lons,lats,72,NSE,'filled'); colorbar;
    figure;
    plot(basin_streamflow(i).mu(j1:j2),'k-','LineWidth',2); hold on;
    plot(SFTS(i,i1:i2)','b--','LineWidth',2);
end

end

