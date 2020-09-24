function [data,iout] = cat_mosart(files,varnames)

    data = struct([]);
    for i = 1 : length(files)
        filename = fullfile(files(i).folder,files(i).name);
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
end

