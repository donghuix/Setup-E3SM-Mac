function show_river_network(fname,col)
    
    if nargin < 2
        col = 'b-';
    end
    dnID   = ncread(fname,'dnID');
    ID     = ncread(fname,'ID');
    latixy = ncread(fname,'latixy');
    longxy = ncread(fname,'longxy');
    [m,n] = size(dnID);
    
    if m> 1 && n == 1
        show_river_1d(dnID,ID,longxy,latixy,col)
    elseif m > 1 && n > 1
        show_river_2d(dnID,ID,longxy,latixy,col)
    end
    
    function show_river_2d(dnID,ID,longxy,latixy,col)
        [m,n] = size(dnID);
            for i = 1 : m
                for j = 1 : n
                    if dnID(i,j) == -9999
                        continue;
                    else
                        [i2,j2] = find(ID == dnID(i,j));
                        plot([longxy(i,j) longxy(i2,j2)], [latixy(i,i) latixy(i2,j2)], col,'LineWidth',2); hold on;
                        i2 = []; j2 = [];
                    end
                end
            end
    end

    function show_river_1d(dnID,ID,longxy,latixy,col)
        m = length(dnID);
        for i = 1 : m
            if dnID(i) == -9999
                continue;
            else
                i2 = find(ID == dnID(i));
                plot([longxy(i) longxy(i2)], [latixy(i) latixy(i2)], col,'LineWidth',2); hold on;
                i2 = [];
            end
        end
    end
end

