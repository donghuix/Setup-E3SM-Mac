clear;close all;clc;

addpath('/Users/xudo627/Developments/inpoly/');
addpath('/Users/xudo627/Developments/Setup-E3SM-Mac/matlab-scripts-to-process-inputs/');

fdom = '/Users/xudo627/Library/CloudStorage/OneDrive-PNNL/projects/cesm-inputdata/share/domains/domain.lnd.r05_oEC60to30v3.190418.nc';
felm = '/Users/xudo627/Library/CloudStorage/OneDrive-PNNL/projects/cesm-inputdata/lnd/clm2/surfdata_map/surfdata_0.5x0.5_simyr2000_c190418.nc';
fmos = '/Users/xudo627/Library/CloudStorage/OneDrive-PNNL/projects/cesm-inputdata/rof/mosart/MOSART_global_half_20180721a.nc';

info_dom = ncinfo(fdom);
info_elm = ncinfo(felm);
info_mos = ncinfo(fmos);

S = shaperead('~/Projects/lnd-ocn-2way/wbd/WBDHU2.shp');

lon = ncread(fmos,'longxy');
lat = ncread(fmos,'latixy');

figure;
plot(lon,lat,'k.'); hold on;
plot(S.X,S.Y,'r-','LineWidth',2);
load('usapolygon.mat');
plot(uslon,uslat,'b-','LineWidth',2);

in = inpoly2([lon(:) lat(:)],[S.X' S.Y']);
figure;
plot(lon(in),lat(in),'k.'); hold on;
plot(S.X,S.Y,'r-','LineWidth',2);

out_netcdf_dir = '.';
tag            = 'test';
numc           = sum(in);
fname_out1 =  sprintf('%s/domain_lnd_%s.nc',out_netcdf_dir,tag);
xc = ncread(fdom,'xc');
yc = ncread(fdom,'yc');
xv = ncread(fdom,'xv');
yv = ncread(fdom,'yv');
mask = ncread(fdom,'mask');
area = ncread(fdom,'area');
frac = ncread(fdom,'frac');
lon1d = xc(in);
lat1d = yc(in);
xv1d  = NaN(4,numc);
yv1d  = NaN(4,numc);
for i = 1 : 4
    tmp = reshape(xv(i,:,:),[720 360]);
    xv1d(i,:) = tmp(in);
    tmp = reshape(yv(i,:,:),[720 360]);
    yv1d(i,:) = tmp(in);
end
frac1d = frac(in);
mask1d = mask(in);
area1d = area(in);

generate_lnd_domain(lon1d,lat1d,xv1d,yv1d,frac1d,mask1d,area1d,fname_out1);

fname_out2 = CreateCLMUgridSurfdatForE3SM(...
                    in, felm,out_netcdf_dir, tag,  ...
                    ones(numc,1).*2.5, ones(numc,1).*5.5e-3,            ... % fdrain,max_drain,
                    ones(numc,1).*6, ones(numc,1),                      ... % ice_imped,snoalb_factor,
                    ones(numc,1).*0.5, [],                            ... % fover,fmax
                    [],[], [],[],               ... % bsw,sucsat,xksat,watsat,
                    ones(numc,1).*0.4, ones(numc,1).*0.14,              ... % fc, mu
                    [], []);   
info_elm_region = ncinfo(fname_out2);

fname_out3 = CreateMOSARTUgridInputForE3SM(in, fmos, out_netcdf_dir, tag);

info_mos_region = ncinfo(fname_out3);
