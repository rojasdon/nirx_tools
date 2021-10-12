% PURPOSE:  function to produce optical timeseries corrected for short channels
% CITATION: Wyser, D., Mattille, M., Wolf, M., Lambercy, O., Scholkmann, F., & Gassert, R. (2020). Short-channel regression in functional near-infrared spectroscopy 
%           is more effective when considering heterogeneous scalp hemodynamics. Neurophotonics, 7(3), 035011. http://doi.org/10.1117/1.NPh.7.3.035011
% INPUTS:   ld, long detector data, 1 x n_time_point vector
%           sd, short detector data, 1 x n_time_point vector (sd and ld
%           size must be the same)
% OUTPUT:   ldc, long detector, corrected by short channel
%           stat, structure containing statistics from regression

function [ldc,stat] = nirx_short_regression(ld, sd)
X = [ones(8615,1) sd']; % regressors, just constant and short channel here
[stat.b,stat.r2,stat.SEb,stat.tvals,stat.pvals,stat.e] = multregr(X,ld');
Yscalp = stat.b(2).*sd; % scalp signal b(1) is intercept
ldc = ld - Yscalp; % corrected signal
        

