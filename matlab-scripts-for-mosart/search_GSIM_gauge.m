function [gsims,in,gsim2] = search_GSIM_gauge(X,Y,xo,yo,show_plot)
    
    load('gsim_info.mat');
    
    if ~isempty(xo)
        xmin = min(X)-2;
        ymin = min(Y)-2;
        xmax = max(X)+2;
        ymax = max(Y)+2;

        in = inpolygon(lon,lat,[xmin xmax xmax xmin xmin],[ymin ymin ymax ymax ymin]);
        in = find(in == 1);
        % find the cloest gauge 
        dist = (lon(in) - xo).^2 + (lat(in) - yo).^2;
        [~,ind2] = sort(dist,'ascend');
    %     disp(ind2);
        ind = find((lon(in) - xo).^2 + (lat(in) - yo).^2 == min((lon(in) - xo).^2 + (lat(in) - yo).^2));

        gsims = gsim_no{in(ind)};
        gsim2= gsim_no(in(ind2));
    else
        in    = inpolygon(lon,lat,X,Y);
        gsims  = gsim_no(in);
        gsim2 = [];
    end

    if show_plot
        figure;
        plot(X,Y,'kx'); hold on;
        plot(lon(in),lat(in),'ro');
        %scatter(lon(in(ind)),lat(in(ind)),100,'s','MarkerFaceColor','g','MarkerEdgeColor','k');
    end

end

