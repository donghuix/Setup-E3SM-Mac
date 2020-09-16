clear;close all;clc

rundir = '/compyfs/xudo627/e3sm_scratch/CLMMOS_USRDAT_Global_inund.2020-09-10-083619/run/';
files = dir([rundir '*.mosart.h0*.nc']);

k = 1;
for i = 1 : length(files)
    filename = fullfile(files(i).folder,files(i).name);
    fprintf(['[' num2str(i/length(files)*100) '%%] ' filename '\n']);
    strs = strsplit(filename,'/');
    strs = strsplit(strs{end},'.');
    datestr = strs{5};
    strs = strsplit(datestr,'-');
    
    if str2double(strs{1}) > 5 && str2double(strs{1}) <= 10
        yr(k) = str2double(strs{1});
        mo(k) = str2double(strs{2});
        da(k) = str2double(strs{3});
        
        if k == 1
            qsur = nanmean(ncread(filename,'QSUR_LIQ'),3);
            frac = nanmean(ncread(filename,'FLOODPLAIN_FRACTION'),3);
        else
            qsur = cat(3,nanmean(ncread(filename,'QSUR_LIQ'),3));
            frac = cat(3,nanmean(ncread(filename,'QSUR_LIQ'),3));
        end
        
        k = k + 1;
    end
    
end