function y = gampdf_custom(x, k, theta)
    % gampdf_custom: Compute Gamma distribution PDF without Statistics Toolbox
    % x     - input values (scalar or vector)
    % k     - shape parameter (k > 0)
    % theta - scale parameter (theta > 0)
    
    if any(x < 0)
        error('x must be non-negative');
    end
    if k <= 0 || theta <= 0
        error('Shape k and scale theta must be positive');
    end

    % Gamma function via Lanczos approximation
    gamma_k = gamma_lanczos(k);
    
    % PDF computation
    y = (x.^(k-1) .* exp(-x./theta)) ./ (gamma_k .* theta.^k);
end