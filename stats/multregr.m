function stat = multregr(X,y,varargin)
% Author: Don Rojas, Ph.D.
% Purpose: Function to calculate multiple linear regression in matrix form from Eq: Y = Xb + e
% Notes: 1. tested accurately using mtcars dataset against R using lm
%           regression and aov package wald.test() function
%        2. Matlab program regress.m offers more quality checks if you have
%           the toolbox
% Citations: 1. Inspired by http://philender.com/courses/multivariate/notes/mr3.html
%            2. Brown, S. (2009). Multiple Linear Regression Analysis: A
%               Matrix Approach with MATLAB. Alabama Journal of Mathematics.
%            3. Gourieroux, C. et al. (1982). Likelihood Ratio Test, Wald Test, and Kuhn-Tucker 
%               Test in Linear Models with Inequality Constraints on the
%               Regression Parameters. Econometrica, 50, 63-80.
% Inputs:   1) X = r x n matrix of IV regressors, r = regressors, n = number of
%                  samples/subjects
%              NOTE: column 1 of X should be ones(n,1) so that the Y
%              intercept is included in the model
%           2) y = DV, must be vector of same size 1 X n as X
% Optional input (in option/value pairs): 
%           1) 'contrast', conmat, where conmat is n contrast by n + 1 condition
%               vector, where n + 1 = size(X,2). Generally, weights should sum to
%               zero. These contrasts are Wald tests between regressors.
%               For other contrasts, create dummy coded columns in X
% Outputs:  1) stat.beta = estimates of beta and intercept, can be
%                          standardized or not, a.k.a. regression
%                          coefficients
%           2) stat.r2 is r-squared
%           3) stat.SEb = standard errors
%           4) stat.AIC = Akaike Information Criterion
%           5) stat.BIC = Bayesian Information Criterion
%           6) stat.tvals is t-statistic (beta / standard error of beta)
%           7) stat.pvals is significance value, two-tailed
%           8) stat.resid is residuals
%           9) stat.contrast contains tvals and pvals for contrast input
%          10) stat.yhat = y-hat, predicted values of y from regression
%           
% History:  12/13/2018 - first working version
%           04/02/2022 - added contrast input/output, changing output to a
%                        structure instead of multiple outputs
%           07/12/2022 - added Akaike and Bayesian Information Criteria
%                        output to stat structure

% TODO: 1) run twice, with standardized and non-standardized predictors/y

% defaults
is_contrast = false;

% check input arguments
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for i=1:2:optargin
            switch varargin{i}
                case 'contrast'
                    conmat = varargin{i+1};
                    is_contrast = true;
                otherwise
                    error('Invalid option!');
            end
        end
    end
end

% check first column for constant, issue warning
n = size(X,1); % n rows
p = size(X,2); % p columns
if any(X(:,1) ~= 1)
    warning('X may not have constant column. Results may be unexpected without y intercept!');
end

% betas
b = pinv(X'*X)*X'*y;

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

% output structure
stat = [];
stat.beta = b; % raw regression coefficients
%stat.beta = ; % beta = b (sd(y)/sd(x)) to standardize
stat.r2 = r2;
stat.F = F;
stat.tvals = tvals;
stat.pvals = pvals;
stat.SEb = SEb;
stat.AIC = n * log(SSresid/n) + 2 * p; % Akaike, 1969
stat.BIC = n * log(SSresid/n) + p * log(n); % Schwarz, 1978
stat.Cov = C;
stat.resid = e;
stat.yhat = yhat;

% contrasts, if any, and their associated stats. These are Wald statistics.
% Wald follows F or X^2 distribution. F stat = T^2. Student T statistic is
% related to Wald W and F as follows: T^2 = W = F. See: https://cran.r-project.org/web/packages/clubSandwich/vignettes...
%   /Wald-tests-in-clubSandwich.html
if is_contrast
    for ii = 1:size(conmat,1)
        con_est = conmat(ii,:)*stat.beta;
        contrast.tvals(ii) = ...
            sqrt(con_est'*pinv(conmat(ii,:)*stat.Cov*conmat(ii,:)')*con_est);
        contrast.pvals(ii) = ...
            betainc(df_resid/(df_resid+(contrast.tvals(ii)^2)),0.5*df_resid,0.5);
    end
    stat.contrast = contrast;
    % check that contrast weights sum to zero (centered)
    if any(sum(conmat,2) ~= 0)
        stat.contrast.warning = "Some contrast row weights do not sum to zero!";
    end
end

end % end of function