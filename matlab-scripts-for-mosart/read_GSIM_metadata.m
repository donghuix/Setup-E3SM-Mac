% ####################################################################### %
% Description: read station information from GSIM metadata and find the 
%              corresponding station number in the dataset
%
% Download data from https://doi.pangaea.de/10.1594/PANGAEA.887477
%
% Author: Donghui Xu
% Date: 08/12/2020
% ####################################################################### %
clear;close all;clc

filename = '~/DATA/GSIM_metadata/GSIM_catalog/GSIM_metadata.csv';
load coastlines.mat

fid = fopen(filename);
k = 0;
while ~feof(fid) % feof(fid) is true when the file ends
      tline = fgetl(fid);
      s = strsplit(tline,',');
      if ( k > 0 )
          gsim_no{k} = s{1};
          agent{k} = s{2};
          tmpstr = s{8};
          river{k} = tmpstr(2:end-1); % remove quotation marks
          if length(s) == 30
              lat(k) = str2double(s{14});
              lon(k) = str2double(s{15});
              area(k)= str2double(s{17});
          elseif length(s) == 29
              lat(k) = str2double(s{13});
              lon(k) = str2double(s{14});
              area(k)= str2double(s{16});
          elseif length(s) == 28
              lat(k) = str2double(s{12});
              lon(k) = str2double(s{13});
              area(k)= str2double(s{15});
          elseif length(s) == 27 
              lat(k) = str2double(s{11});
              lon(k) = str2double(s{12});
              area(k)= str2double(s{14});
          end

          if ( k > 1 )
            assert(~isnan(lat(k)) && ~isnan(lon(k)));
          end

          frac_missing_days(k) = str2double(s{24});
          year_start(k) = str2double(s{25});
          year_end(k)   = str2double(s{26});
      end
      k = k + 1;
end
s = strsplit(tline,',');
fclose(fid); % close the file

ind = strcmp(river,'AMAZON'); ind = find(ind == 1);

bigriver = {'MACKENZIE RIVER', 'MISSISSIPPI RIVER', 'ORINOCO', 'NA', 'DANUBE RIVER', ...
            'VOLGA','OB','Godavari','YANGTZE RIVER (CHANG JIANG)', 'YENISEY', ...
            'LENA', 'KOLYMA'};
gsimnum = [12730; 26879; 30493; 3546;  19998; ...
           20169; 20090; 17632; 13340; 20059; ...
           20028; 20107; ];
gsimid  = {'CA_0006066','US_0005806', 'VE_0000009', 'BR_0000244', 'RO_0000038', ...
           'RU_0000160','RU_0000081', 'IN_0000098', 'CN_0000180', 'RU_0000050', ...
           'RU_0000019','RU_0000098'};

Basins = {'Mackenzie', 'Mississippi', 'Orinoco', 'Amazon', 'Danube',  ...
          'Volga', 'Ob', 'Godavari',  'Yangtze', 'Yenisey', ...
          'Lena', 'Kolyma', 'Murray-Darling'}; %'Pechora','Zaire','Irrawaddy',
S = shaperead('/Users/xudo627/projects/land-river-two-way-coupling/major_basins_of_the_world_0_0_0/Major_Basins_of_the_World.shp');


figure;
plot(lon,lat,'b.'); hold on
plot(lon(ind),lat(ind),'ro'); 
plot(coastlon,coastlat,'k-','LineWidth',2);


ibasins = [];
for i = 1 : length(S)
    if any(strcmp(Basins,S(i).NAME))
        fprintf(['i = ' num2str(i) ': ' S(i).NAME '\n']);
        plot(S(i).X,S(i).Y,'r-','LineWidth',2); hold on
        if strcmp(S(i).NAME,'Amazon') && i == 176
            ibasins = [ibasins; i];
        else
            ibasins = [ibasins; i];
        end
    end
end
axis equal;
ibasins = [5; 46; 149; 176; 43; 16; 253; 121; 97; 3; 252; 2; 228];

