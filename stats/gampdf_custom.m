% PURPOSE: Compute Gamma distribution PDF without Statistics Toolbox
% INPUTS:   x     - input values (scalar or vector)
%           k     - shape parameter (k > 0)
%           theta - scale parameter (theta > 0)
% OUTPUTS:  y     - gamma pdf
% CITATION: Johnson et al. (1994). Continuous Univariate Distributions,
%           Vol 1 (2nd ed.). Wiley Press
function y = gampdf_custom(x, k, theta)
    % check validity of input
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