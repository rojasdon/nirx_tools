% autoregression pseudo code bypass of mathworks econometrics toolbox

% Step 1. Create lagmatrices for number of orders. i.e., if max order = 4,
% lagmatrices of 4 lags should be created for y.
% Step 2. Could do stepwise regression model to get weights for model (this step
% is only necessary for optimum model order. That can be determined outside
% of the code by AIC/BIC criteria. So, do 3 instead.
% Step 3. Conduct regression on lagmatrices, using only non nan data
% points, at each order. Betas = coefficients of AR model.
% Step 4. Use BIC to determine best model order, and use those weights in
% AR-IRL within nirx_glm.m to conduct further analysis.

% NOTE: If you write this function out, then use multregr.m to estimate it,
% the code will be independent of econometrics toolbox. Must also write a
% lagmatrix.m alternative. Can use convmtx function, as in lags =
% convmtx(y,order);

% convmtx output is similar to lagmatrix, but if convmtx order is 4, only
% 2:4 will be lagged. 1 will be original y vector input. For lagmatrix, 1
% will be lag 1. So, lags(:,1) in convmtx(y,4) is actually = y, and
% lags(:,2) = 1st lag (order = 1).

% https://www.mathworks.com/matlabcentral/answers/618833-manually-write-code-for-a-vector-autoregression
maxorder = 20;
npoints = length(y);
for lag = 1:maxorder
    ylags = timelags(y,lag);
    yy = ylags(:,1);
    xx = ylags(:,2:end);
    X = [ones(size(yy,1),1) xx];
    stats(lag) = multregr(X,yy);
end
BIC = [stats.BIC];
[~,ind]=min(BIC);
coeff = stats(ind).beta;