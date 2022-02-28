clear;close all;clc;

addpath('/Users/xudo627/donghui/CODE/dengwirda-inpoly-355c57c/');

load('usapolygon.mat');
S = shaperead('/Users/xudo627/projects/Susquehanna/watershed/boundary.shp');
cols = distinguishable_colors(20);

filename = '/Users/xudo627/projects/cesm-inputdata/US_reservoir_8th_NLDAS3_c20161220_updated_20170314.nc';

lon = ncread(filename,'lon');
lat = ncread(filename,'lat');

DamID_Spatial =ncread(filename,'DamID_Spatial');
gridID_from_Dam = ncread(filename,'gridID_from_Dam');

[lon,lat] = meshgrid(lon,lat); lon = lon'; lat = lat';

in = inpolygon(lon,lat,S.X,S.Y);

ind = find(~isnan(DamID_Spatial) & in);
figure; set(gcf,'Position',[10 10 1200 1000]);

for i = 1 : length(ind)
    subplot(5,3,i);
    scatter(lon(ind(i)),lat(ind(i)),72,'o','MarkerFaceColor','g','MarkerEdgeColor','k'); hold on;
    tmp = gridID_from_Dam(DamID_Spatial(ind(i)),:);
    tmp = tmp(~isnan(tmp));
    scatter(lon(tmp),lat(tmp),4,'s','MarkerFaceColor','k','MarkerEdgeColor','b');
    plot(S.X,S.Y,'k-','LineWidth',2);
    title(['Dam #' num2str(i)],'FontSize',15,'FontWeight','bold');
    if i == 1
        leg = legend('Dam','Dependent grid cells');
        leg.FontSize = 15;
        leg.FontWeight = 'bold';
    end
end
