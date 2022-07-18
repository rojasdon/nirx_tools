function ylags = timelags(y,lags)
% PURPOSE: to create a matrix of lagged timeseries, useful for AR model
% order determination/autocorrelation functions. Avoids need for
% lagmatrix.m function in econometrics toolbox.
% AUTHOR: D. Rojas
% INPUTS: y, npoint x 1 timeseries
%         lags, integer number of lagged timeseries to produce
% OUTPUTS: ylags, npoints x nlags matrix
% HISTORY: 07/13/2022 - first version

% get lagged timeseries
ylags = convmtx(y,lags + 1); % add 1 b/c lags(:,1) == input y