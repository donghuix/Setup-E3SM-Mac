function [data,isgrid2d] = cat_elm(files,varnames,ind)
    
    if nargin == 2
        readall = 1;
    else
        readall = 0;
    end
    
    data = struct([]);
    for i = 1 : length(files)
        filename = fullfile(files(i).folder,files(i).name);
        fprintf([filename '\n']);
        for j = 1 : length(varnames)
            if i == 1
                dims = size(ncread(filename,varnames{j}));
                ndim(j) = length(dims);
                ncid = netcdf.open(filename,'NC_NOWRITE');
                [dimname, nx] = netcdf.inqDim(ncid,0);
                if strcmp(dimname,'lndgrid')
                    isgrid2d = 0;
                elseif strcmp(dimname,'lon')
                    isgrid2d = 1;
                    [dimname, ny] = netcdf.inqDim(ncid,1);
                    if readall == 0
                        [row,col] = ind2sub([nx,ny],ind);
                    end
                end
                netcdf.close(ncid);
            end
            tmpread = ncread(filename,varnames{j});
            if readall == 1
                if i == 1
                    data(1).(varnames{j}) = tmpread;
                else
                    data.(varnames{j}) = cat(ndim(j)+1,data.(varnames{j}),tmpread);
                end
            else
                if isgrid2d == 1
                    for irow = 1 : length(ind)
                        if ndim(j) == 2
                            if irow == 1
                                tmpall = tmpread(row(irow),col(irow));
                            else
                                tmpall = [tmpall; tmpread(row(irow),col(irow))];
                            end
                        elseif ndim(j) == 3
                            if irow == 1
                                tmpall = tmpread(row(irow),col(irow),:);
                            else
                                tmpall = cat(1, tmpall, tmpread(row(irow),col(irow),:));
                            end
                        elseif ndim(j) == 4
                            if irow == 1
                                tmpall = tmpread(row(irow),col(irow),:,:);
                            else
                                tmpall = cat(1, tmpall, tmpread(row(irow),col(irow),:,:));
                            end
                        elseif ndim(j) == 5
                            if irow == 1
                                tmpall = tmpread(row(irow),col(irow),:,:,:);
                            else
                                tmpall = cat(1, tmpall, tmpread(row(irow),col(irow),:,:,:));
                            end
                        else
                            error('check output dimension!!!');
                        end
                    end
                elseif isgrid2d == 0
                    if ndim(j) == 1
                        tmpall = tmpread(ind);
                    elseif ndim(j) == 2
                        tmpall = tmpread(ind,:);
                    elseif ndim(j) == 3
                        tmpall = tmpread(ind,:,:);
                    elseif ndim(j) == 4
                        tmpall = tmpread(ind,:,:);
                    else
                        error('check output dimension!!!');
                    end
                end
                if i == 1
                    data(1).(varnames{j}) = tmpall;
                else
                    data.(varnames{j}) = cat(ndim(j)+1,data.(varnames{j}),tmpall);
                end
            end
        end
    end
    
end
