function data = cat_elm(files,varnames)

    data = struct([]);
    for i = 1 : length(files)
        filename = fullfile(files(i).folder,files(i).name);
        fprintf([filename '\n']);
        for j = 1 : length(varnames)
            if i == 1
                data(1).(varnames{j}) = ncread(filename,varnames{j});
                dims = size(data(1).(varnames{j}));
                ndim = length(dims);
            else
                data.(varnames{j}) = cat(ndim+1,data.(varnames{j}),ncread(filename,varnames{j}));
            end
        end
    end
    
end
