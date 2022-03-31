function [b,r2,SEb,tvals,pvals,e]=multregr(X,y,varargin)
% Author: Don Rojas, Ph.D.
% Function to calculate multiple linear regression in matrix form from Eq: Y = Xb + e
% NOTES: 1. inspired by http://philender.com/courses/multivariate/notes/mr3.html
%        2. tested accurately against mtcars dataset in R using lm
%           regression
%        3. Matlab program regress.m offers more quality checks if you have
%           the toolbox
% inputs:   1) X = r x n matrix of IV regressors, r = regressors, n = number of
%                  samples/subjects
%              NOTE: column 1 of X should be ones(n,1) so that the Y
%              intercept is included in the model
%           2) y = DV, must be vector of same size 1 X n as X
% optional input (in option/value pairs): 
%           1) 'adjustment',xcol (xcol indicates column of X input that
%               will be used to adjust output);
% outputs:  1) b = estimates of beta and intercept
%           2) r2 is r-squared
%           3) SEb = standard errors
%           4) tvals is t-statistic (beta / standard error of beta)
%           5) pvals is significance value, two-tailed
%           6) e is residuals
%           7) ypred (optional) is output of regression, adjusted for
%              covariate indicated in X, indicated by optional input
%           
% first created: 12/13/2018

% check input arguments
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for i=1:2:optargin
            switch varargin{i}
                case 'adjusted'
                    adjustment = varargin{i+1};
                    adjust = 1;
                otherwise
                    error('Invalid option!');
            end
        end
    end
end

% check first column for constant, issue warning
n = size(X,1); % n rows
if any(X(:,1) ~= 1)
    warning('X may not have constant column. Results may be unexpected without y intercept!');
end

% betas
b = inv(X'*X)*X'*y;

% predicted scores and residuals
yhat = X*b; % predicted scores
e = y - yhat; % residuals

% partition SS and coefficient of determination
SSresid = e'*e;
SStotal = y'*y - (sum(y)^2/n);
SSreg = SStotal - SSresid;
r2   = SSreg/SStotal;
F = SSreg/SSresid;

% standard errors
k = size(X,2); % k regressors, some references list as p
df_resid = n - k;
C = (SSresid/(n - k)) * inv(X'*X); % covariance of standard errors
SEb =  sqrt(diag(C));

% significance of betas using t-scores and incomplete beta function
tvals = b./SEb;
for ii = 1:length(tvals)
    pvals(ii) = betainc(df_resid/(df_resid+(tvals(ii)^2)),0.5*df_resid,0.5);
end
pvals = pvals'; % just to make it consistent with other col vectors

end % end of function