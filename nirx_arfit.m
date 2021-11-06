% purpose: a wrapper around the nirx-toolbox ar_fit routine, used for
% pre-whitening design and data for glm (e.g., ar(1)...ar(n)
% INPUTS
%   p, column vector of timeseries, or residuals 
%   order, order of ar model to fit
% OUTPUT
%   q, vector of coefficients, length = order
function q = nirx_arfit(p, order)
    try
        q = nirs.math.ar_fit(p,order);
    catch
        error('To run nirx_arfit.m, nirs-toolbox must be installed!');
    end
end
        




