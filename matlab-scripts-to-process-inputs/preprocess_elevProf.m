function [e_eprof3,a_eprof3] = preprocess_elevProf (fname,debug)
    
    if nargin == 1
        debug =0;
    end
    
    rdep = ncread(fname,'rdep');
    rwid = ncread(fname,'rwid');
    area = ncread(fname,'area');
    rlen = ncread(fname,'rlen');
    e_eprof  = ncread(fname,'ele');
    
    threshold_slpRatio = 10;
    a_chnl_max = 0.70;
    
    numr = length(rdep);
    
    for iu = 1 : numr
        if e_eprof(iu, 2) - e_eprof(iu, 1)  > threshold_slpRatio*(e_eprof(iu, 3) - e_eprof(iu, 2))
            e_eprof(iu, 1) = e_eprof(iu, 2) - threshold_slpRatio * (e_eprof(iu, 3) - e_eprof(iu, 2));
        end
    end
    
    for iu = 1 : numr
        for k = 2 : 11
            if e_eprof(iu, k-1) >= e_eprof(iu, k)
                e_eprof(iu, k) = e_eprof(iu, k-1) + 0.01;
            end
        end
    end
    
    a_eprof = NaN(numr,12);
    
    for i = 1 : numr
        a_chnl(i) = rwid(i)*rlen(i)/area(i);
        if a_chnl(i) - a_chnl_max > 1e-5
            %fprintf(['Fix river width for cell ' num2str(i) '\n']);
            rwid(i) = area(i) * a_chnl_max / rlen(i); 
            a_chnl(i) = a_chnl_max;
        end

        for j = 1 : 11
            a_eprof(i,j) = (j-1)*0.1;
        end
        a_eprof(i,12) = 1;

        for j = 1 : 10
            if a_eprof(i,j) <= a_chnl(i) && a_chnl(i) < a_eprof(i,j+1)
                e_chnl(i) = interpolation_linear(a_chnl(i), a_eprof(i,j), a_eprof(i,j+1), e_eprof(i,j), e_eprof(i,j+1));
                ipt_bl_bktp(i) = j; 
            end
        end
    end
    
    a_eprof3 = NaN(numr,12);
    e_eprof3 = NaN(numr,12);
    alfa3    = NaN(numr,11);
    for iu = 1 : numr
        a_eprof3(iu, 1) = 0;
        e_eprof3(iu, 1) = 0;
        a_eprof3(iu, 2) = a_chnl(iu);
        e_eprof3(iu, 2) = 0;

        for j = ipt_bl_bktp(iu)+1 : 11
            k = j - ipt_bl_bktp(iu) + 2;
            a_eprof3(iu, k) = a_eprof(iu, j); 
            e_eprof3(iu, k) = e_eprof(iu, j) - e_chnl(iu);
        end
        a_eprof3(iu, k+1) = a_eprof3(iu, k);
        e_eprof3(iu, k+1) = 10000;
        npt_eprof3(iu)    = k + 1;

        for j = 2 : npt_eprof3(iu) - 1
            if abs(e_eprof3(iu,j+1) - e_eprof3(iu,j)) > 1e-10
                alfa3(iu,j) = (a_eprof3(iu, j+1) - a_eprof3(iu, j)) / (e_eprof3(iu, j+1) - e_eprof3(iu, j));
            else
                if debug == 1
                    fprintf(['ERROR: Dvided by zero: iu = ' num2str(iu) ', j= ' num2str(j) '\n']);
                end
            end
        end
    end


end

