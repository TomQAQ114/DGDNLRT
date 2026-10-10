function W = compute_DGD_weight(mask, mu1, mu2, sigma1, sigma2, lambda)

    alpha1 = 0.5;
    alpha2 = 0.5;
    eps_val = 1e-10; 
    
    mask = double(mask); % 转为双精度浮点型

   
    coeff1 = 1 / (sqrt(2*pi) * (sigma1 + eps_val));
    coeff2 = 1 / (sqrt(2*pi) * (sigma2 + eps_val));
    

    exp_part1 = exp( -0.5 * ((mask - mu1).^2) / ((sigma1^2) + eps_val) );
    exp_part2 = exp( -0.5 * ((mask - mu2).^2) / ((sigma2^2) + eps_val) );
    
    p1 = coeff1 * exp_part1;
    p2 = coeff2 * exp_part2;


    numerator = alpha1 * p2;
    denominator = alpha1 * p1 + alpha2 * p2 + eps_val; 
    P_open = numerator ./ denominator;
    

    P_open = max(0, min(1, P_open));

    term1 = P_open / (mu1^2 + eps_val);
    term2 = (1 - P_open) / (mu2^2 + eps_val);
    
    W = lambda * (term1 + term2);



end