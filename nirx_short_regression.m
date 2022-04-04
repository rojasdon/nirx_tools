% PURPOSE:  function to produce optical timeseries corrected for short channels
% AUTHOR:   Don  Rojas, Ph.D.
% CITATION: Wyser, D., Mattille, M., Wolf, M., Lambercy, O., Scholkmann, F., & Gassert, R. (2020). Short-channel regression in functional near-infrared spectroscopy 
%           is more effective when considering heterogeneous scalp hemodynamics. Neurophotonics, 7(3), 035011. http://doi.org/10.1117/1.NPh.7.3.035011
% INPUTS:   lc, long channel data, 1 x n_time_point vector
%           sc, short channel data, 1 x n_time_point vector (sd and ld
%           size must be the same)
% OUTPUT:   lcc, long channel, corrected by short channel
%           stat, structure containing statistics from regression
%           scalp, short channel estimated scalp signal (i.e., lc - scalp =
%           lcc)
% Revision history
% 03/03/2022 - 1. changed variable naming convention to avoid confusion between
%   detectors (single optodes) and channels (paired optodes) 2. added
%   optional return of scalp estimate
% 03/04/2022 - bugfix on length of regression constant column

function [lcc,stat,scalp] = nirx_short_regression(lc, sc)
X = [ones(length(lc),1) sc']; % regressors, just constant and short channel here
stat = multregr(X,lc');
scalp = stat.beta(2).*sc; % scalp signal b(1) is intercept
lcc = lc - scalp; % corrected long signal
        

