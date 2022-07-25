function ylags = timelags(y,lags)
% PURPOSE: to create a matrix of lagged timeseries, useful for AR model
% order determination/autocorrelation functions. Avoids need for
% lagmatrix.m function in econometrics toolbox.
% AUTHOR:   D. Rojas
% NOTE:     using convmtx for this is easier, but requires Signal
%           Processing Toolbox
% INPUTS:   y, npoint x 1 timeseries
%           lags, integer number of lagged timeseries to produce
% OUTPUTS:  ylags, npoints x nlags matrix
% HISTORY:  07/13/2022 - first version
% SEE ALSO: ar_model

% get lagged timeseries
lags = eye(lags+1); % +1 to include the original waveform
for lag = 1:size(lags,1)
    ylags(:,lag) = conv(y,lags(lag,:),'valid');
end