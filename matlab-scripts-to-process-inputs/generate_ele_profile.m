function ele_uq = generate_ele_profile(ele,np,nm)

    ele_uq = zeros(np+nm,11);
    de = 0.1/np;
    d = [0 0.1:-de:0.02 0].*(ele-ele(1));
    for i = 1 : 11
        if i == 1 || i == 11
            ele_uq(:,i) = ones(np+nm,1).*ele(i);
        else
            for j = 1 : np+nm
                if j <= np
                    ele_uq(j,i) = ele(i) - (j-1)*d(i);
                else
                    ele_uq(j,i) = ele(i) + (j-np)*d(i);
                end
            end
        end
    end
    
    for j = 1 : np + nm
        ele1 = ele_uq(j,:);
        for i = 2 : 11
            if ele1(i) > ele(11)
                ele1(i) = ele(11)-1;
            end
            if ele1(i) - ele1(i-1) < 0.001
                ele1(i) = ele1(i-1) + 0.1;
            end
        end
        ele_uq(j,:) = ele1;
    end
    
end
