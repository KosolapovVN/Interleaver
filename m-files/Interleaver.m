% Algorithm of interleaver
    K = 64;                 % number of bits in frame
    bits_pos_in = 1:K;      % bits position before interleaver

% vectors p_values and v_values according to algorithm 
    p_values = [7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97 101 103 107 109 113 127 131 137 139 149 151 157 163 167 173 179 181 191 193 197 199 211 223 227 229 233 239 241 251 257];
    v_values = [3 2 2 3 2 5 2 3 2 6 3 5 2 2 2 2 7 5 3 2 3 5 2 5 2 6 3 3 2 3 2 2 6 5 2 5 2 2 2 19 5 2 3 2 3 2 6 3 7 7 6 3];
    value_index = 0;

% Determine number of rows in rectangular matrix and inter-row permutation pattern 
    if K <= 39
        error('K < 40!');
    elseif K <= 159
        R = 5;
        T = [4 3 2 1 0];
    elseif K <= 200
        R = 10;
        T = [9 8 7 6 5 4 3 2 1 0];
    elseif K <= 480
        R = 20;
        T = [19 9 14 4 0 2 5 7 12 18 10 8 13 17 3 1 16 6 15 11];        
    elseif K <= 530
        R = 10;
        T = [9 8 7 6 5 4 3 2 1 0];
    elseif K <= 2280
        R = 20;
        T = [19 9 14 4 0 2 5 7 12 18 10 8 13 17 3 1 16 6 15 11];
    elseif K <= 2480
        R = 20;
        T = [19 9 14 4 0 2 5 7 12 18 16 13 17 15 3 1 6 11 8 10];
    elseif K <= 3160
        R = 20;
        T = [19 9 14 4 0 2 5 7 12 18 10 8 13 17 3 1 16 6 15 11];
    elseif K <= 3210
        R = 20;
        T = [19 9 14 4 0 2 5 7 12 18 16 13 17 15 3 1 6 11 8 10];
    elseif K <= 5114
        R = 20;
        T = [19 9 14 4 0 2 5 7 12 18 10 8 13 17 3 1 16 6 15 11];
    else
        error('K > 5114!');
    end

% Determine number of columns
    if value_index == 0
        value_index = 1;
    while K > R*(p_values(value_index)+1)
        value_index = value_index+1;
    end
        p = p_values(value_index);
        if K <= R*(p-1)
            C = p-1;
        elseif K <= R*p
            C = p;
        else
            C = p+1;
        end
    end
    
% Forming matrix 
    matrixRC = reshape([bits_pos_in,zeros(1,R*C-length(bits_pos_in))],C,R)';  % zeros in the end of last row
    v = v_values(value_index);

    s = zeros(1,p-1);
    s(1) = 1;

    for j = 2:length(s)
        s(j) = mod(v*s(j-1),p);
    end
    
    q = zeros(1,R);
    q(1) = 1; 
    for i = 2:length(q)  
        prime_index = 1;
        while ~(p_values(prime_index) > q(i-1) && gcd(p_values(prime_index),p-1) == 1)
            prime_index = prime_index+1;
        end
        q(i) = p_values(prime_index);
    end
        
    r=zeros(size(q));
    r(T+1) = q;
    for i = 0:(R-1)
        if C == p
            U = [s(mod((0:(p-2))*r(i+1), p-1)+1),0];
        elseif C == p+1
            U = [s(mod((0:(p-2))*r(i+1), p-1)+1),0,p];
        if i == R-1 && K == R*C
            U([1,length(U)]) = U([length(U),1]);
        end
        elseif C == p-1
            U = s(mod((0:(p-2))*r(i+1), p-1)+1)-1;
        end
        matrixRC(i+1,:) = matrixRC(i+1,U+1);    
    end               
    
    matrix_final(:,:) = matrixRC(T+1,:);
    bits_pos_out = reshape(matrix_final, 1, R*C);   % matrix [RxC] to vector
    bits_pos_out = bits_pos_out(bits_pos_out > 0);  % remove zeros

% Forming Data for SPI interface
    k_byte = K/8;                       % number of bytes
    data_byte = uint8(1:k_byte);        % vector of bytes from 1 to K/8  

% Forming data bit vector from data byte vector
    data_bit = [];                      % empty data bit vector
    for ii = 1 : k_byte
        data_bit = [data_bit bitget(data_byte(ii), 8:-1:1)];         % extract bits from byte
    end

% Interleave bits according to rule
    for jj = 1 : K
        data_bit_interl(jj) = data_bit(bits_pos_out(jj));            % interleave bits
    end 
% Make bits to hex data
    data_interl_resh = reshape(data_bit_interl, [8,K/8]);            % make matrix 8x77
    data_interl_byte = bit2int(data_interl_resh, 8, true);

    data_hex_input  = dec2hex(data_byte);                            % input bytes to interleaver
    data_hex_out    = dec2hex(data_interl_byte);                     % output bytes from interleaver

    str_in      = join(cellstr(data_hex_input));
    str_out     = join(cellstr(data_hex_out));

    fid1 = fopen('data_in_hex.dat','w');            
    fid2 = fopen('data_out_hex.dat','w');

    fprintf(fid1,'%s ',str_in{1});
    fprintf(fid2,'%s ',str_out{1});

    fclose('all');

    
