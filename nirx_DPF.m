function dpf = nirx_DPF(wl,age)
% function to calculate differential path length based on wavelength and
% age. Source of equations: Scholkmann, F., & Wolf, M. (2013). 
% General equation for the differential pathlength factor of the frontal 
% human head depending on wavelength and age. Journal of Biomedical Optics, 
% 18(10), 105004. http://doi.org/10.1117/1.JBO.18.10.105004
% INPUTS: wl, wavelengths, 1 x n array
%         age, of subject in years
% OUTPUT: DPF, differential pathlength factors, 1 x n, where n = number of
%         wl

% parameters from Scholkmann paper, equation 7, variables follow greek
% lettering in equation in paper
alpha = 223.3;
beta = 0.05624;
gamma = 0.8493;
delta = -5.723e-7;
epsilon = 0.001245;
zeta = -0.9025;

% general equation 7
for ii=1:length(wl)
    lambda = wl(ii);
    dpf(ii) = alpha + beta.*age.^gamma + delta.*lambda.^3 + epsilon.*lambda.^2 + zeta.*lambda;
end