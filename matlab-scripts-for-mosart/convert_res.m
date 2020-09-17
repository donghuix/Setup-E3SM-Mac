function Z = convert_res(A,u,d)
    %u = 5;       %upsampling factor
    %d = 12;      %downsampling factor
    t = d/u;     %reduction factor
    [m,n]=size(A);
    L1=speye(m); L2=speye(round(m/t))/u;
    R1=speye(n); R2=speye(round(n/t))/u;
    L=repelem(L2,1,d) * repelem(L1,u,1);
    R=(repelem(R2,1,d) * repelem(R1,u,1)).';
    Z= L*(A*R);
end

