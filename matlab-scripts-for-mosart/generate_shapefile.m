function S = generate_shapefile(X,Y,dnID,ID,filename)
    m = length(dnID);
    S = struct([]);
    k = 1;
    for i = 1 : m
        if dnID(i) == -9999
            continue;
        else
            i2 = find(ID == dnID(i));
            xcr = X(i);
            ycr = Y(i);
            xdn = X(i2);
            ydn = Y(i2);
            S(k).Geometry = 'Line';
            S(k).X = [xcr, xdn, NaN];
            S(k).Y = [ycr, ydn, NaN];
            S(k).dire = k - 1;
            S(k).BoundingBox = [min(xcr,xdn) min(ycr,ydn); max(xcr,xdn) max(ycr,ydn)];
            i2 = [];
        end
    end
    shapewrite(S,filename);
end

