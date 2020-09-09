function [var_max, ic, is, ie] = find_max_accumulated(var,len)
    var_acc = movmean(var,len);
    if mod(len,2) == 1 % odd number
        var_acc(1:(len-1)/2) = NaN;
        var_acc(end-(len-1)/2+1:end) = NaN;
    elseif mod(len,2) == 0 % even number
        var_acc(1:len/2) = NaN;
        var_acc(end-len/2+2:end) = NaN;
    end
    
    [var_max,ic] = max(var_acc);
    var_max = var_max*len;
    
    if mod(len,2) == 1 % odd number
        is = ic - (len-1)/2;
        ie = ic + (len-1)/2;
    elseif mod(len,2) == 0 % even number
        is = ic - len/2;
        ie = ic + len/2 -1;
    end
end

