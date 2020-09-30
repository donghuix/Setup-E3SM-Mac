function data = cat_elm(files,varnames)

    data = struct([]);
    for i = 1 : length(files)
        filename = fullfile(files(i).folder,files(i).name);
        for j = 1 : length(varnames)
            if i == 1
                data(1).(varnames{j}) = ncread(filename,varnames{j});
                ncid = netcdf.open(filename,'NC_NOWRITE');
                [dimname, dimlen] = netcdf.inqDim(ncid,1);
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
