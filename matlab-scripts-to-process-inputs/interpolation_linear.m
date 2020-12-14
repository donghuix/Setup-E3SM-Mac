function y = interpolation_linear(x, x1, x2, y1, y2)
    
    if abs(x1 - x2) > 1e-10
        y = (y2-y1)*(x-x1)/(x2-x1) + y1;
    else
        error('interpolation error\n');
    end
end