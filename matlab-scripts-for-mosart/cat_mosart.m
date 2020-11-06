function [data,iout] = cat_mosart(files,varnames,icontributing)
    
    if nargin == 2
        icontributing = [];
    end
    data = struct([]);
    if isempty(icontributing)
        for i = 1 : length(files)
            filename = fullfile(files(i).folder,files(i).name);
            fprintf([files(i).name '\n'])
            for j = 1 : length(varnames)
                if i == 1
                    areatotal = ncread(filename,'areatotal2');
                    iout = find(areatotal == max(areatotal));
                    data(1).(varnames{j}) = ncread(filename,varnames{j});
                    ncid = netcdf.open(filename,'NC_NOWRITE');
                    [dimname, dimlen] = netcdf.inqDim(ncid,0);
                    netcdf.close(ncid);
                    if strcmp(dimname,'gridcell')
                        ndim = 1;
                    end
                else
                    data.(varnames{j}) = cat(ndim+1,data.(varnames{j}),ncread(filename,varnames{j}));
                end
            end
        end
    else
        for i = 1 : length(files)
            filename = fullfile(files(i).folder,files(i).name);
            fprintf([files(i).name '\n'])
            for j = 1 : length(varnames)
                if i == 1
                    areatotal = ncread(filename,'areatotal2');
                    iout = find(areatotal(icontributing) == max(areatotal(icontributing)));
                    tmp = ncread(filename,varnames{j});
                    data(1).(varnames{j}) = tmp(icontributing);
                    ndim = 1;
                    if length(size(tmp)) > ndim + 1
                        error('dimension error');
                    end
                else
                    tmp = ncread(filename,varnames{j});
                    data.(varnames{j}) = cat(ndim+1,data.(varnames{j}),tmp(icontributing));
                end
            end
        end
    end
end

