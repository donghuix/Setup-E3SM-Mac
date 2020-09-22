function show_river_network(dnID,ID,longxy,latixy,col)
    
    if nargin < 5
        col = 'b-';
    end
    
    if ndims(dnID) == 1
        show_river_1d(dnID,ID,longxy,latixy,col)
    elseif ndims(dnID) == 2
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

