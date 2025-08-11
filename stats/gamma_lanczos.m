function g = gamma_lanczos(z)
    % gamma_lanczos: Compute the gamma function without toolbox
    % Lanczos approximation parameters
    p = [ ...
        676.5203681218851,  -1259.1392167224028, ...
        771.32342877765313, -176.61502916214059, ...
        12.507343278686905, -0.13857109526572012, ...
        9.9843695780195716e-6, 1.5056327351493116e-7];
    
    if z < 0.5
        % Reflection formula for better accuracy for small z
        g = pi / (sin(pi*z) * gamma_lanczos(1-z));
        return
    end
    
    z = z - 1;
    x = 0.99999999999980993;
    for i = 1:length(p)
        x = x + p(i) / (z + i);
    end
    t = z + length(p) - 0.5;
    
    g = sqrt(2*pi) * t^(z+0.5) * exp(-t) * x;
end