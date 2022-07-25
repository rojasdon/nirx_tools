function [coeff, order] = ar_model(y,order,varargin)
% PURPOSE:  autoregression bypass of mathworks econometrics toolbox. Use
%           that if you have it. The code is still dependent on signal
%           processing toolbox at the moment.
% AUTHOR: Don Rojas
% Logic, as follows:
%   Step 1. Create lagmatrices for number of orders. i.e., if max order = 4,
%       lagmatrices of 4 lags should be created for y.
%   Step 2. Could do stepwise regression model to get weights for model (this step
%       is only necessary for optimum model order. That can be determined outside
%       of the code by AIC/BIC criteria. So, do 3 instead.
%   Step 3. Conduct regression on lagmatrices, using only non nan data
%       points, at each order. Betas = coefficients of AR model.
%   Step 4. Use BIC to determine best model order, and use those weights in
%       AR-IRL within nirx_glm.m to conduct further analysis.
% INPUTS: y, timeseries to estimate
%         order, if provided alone, specifies the model order desired
%         'maxorder'| integer maximum order to estimate. Coefficients will
%         be estimated for order up to the order requested. Using maxorder
%         overrides the order input.
% OUTPUTS: coeff = coefficients for AR model n order x 1
%          lag = order of the model (only informative if 'maxorder' option
%          employed.
% NOTE: Related discussion here:
%       https://www.mathworks.com/matlabcentral/answers/618833-manually-write-code-for-a-vector-autoregression
% SEE ALSO: timelags

% defaults
maxorder = order;

% check input arguments
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for i=1:2:optargin
            switch varargin{i}
                case 'maxorder'
                    maxorder = varargin{i+1};
                otherwise
                    error('Invalid option!');
            end
        end
    end
end

% lag matrices and estimation
for lag = 1:maxorder
    ylags = timelags(y,lag);
    yy = ylags(:,1);
    xx = ylags(:,2:end);
    X = [ones(size(yy,1),1) xx];
    stats(lag) = multregr(X,yy);
end
BIC = [stats.BIC];
[~,order]=min(BIC);
coeff = stats(order).beta;