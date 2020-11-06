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
        if ~isfield(icontributing,'icontributing')
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
        else
            for i = 1 : length(files)
                filename = fullfile(files(i).folder,files(i).name);
                fprintf([files(i).name '\n'])
                for j = 1 : length(varnames)
                    tmp = ncread(filename,varnames{j});
                    for k = 1 : length(icontributing)
                        if ~isempty(icontributing(k).icontributing)
                        if i == 1
                            areatotal = ncread(filename,'areatotal2');
                            iout(k)   = find(areatotal(icontributing(k).icontributing) == max(areatotal(icontributing(k).icontributing)));
                            data(k).(varnames{j}) = tmp(icontributing(k).icontributing);
                            ndim = 1;
                            if length(size(tmp)) > ndim + 1
                                error('dimension error');
                            end
                        else
                            data(k).(varnames{j}) = cat(ndim+1,data(k).(varnames{j}),tmp(icontributing(k).icontributing));
                        end
                        end
                    end
                end
            end
        end
    end
end

