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
% Outputs:  1) stat.beta = estimates of beta and intercept
%           2) stat.r2 is r-squared
%           3) stat.SEb = standard errors
%           4) stat.tvals is t-statistic (beta / standard error of beta)
%           5) stat.pvals is significance value, two-tailed
%           6) stat.yhat is predicted y
%           7) stat.resid is residuals, y - yhat
%           8) stat.contrast contains tvals and pvals for contrast input
%           
% History:  12/13/2018 - first working version
%           04/02/2022 - added contrast input/output, changing output to a
%                        structure instead of multiple outputs
%           04/21/2022 - return yhat (predicted y)
%           04/25/2022 - added non-negative regression option via stats
%                        toolbox, if installed

% defaults
is_contrast = false;
non_neg = false; % non-negative regression option, must have stats toolbox installed

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
                case {'nonnegative','nn'}
                    v = ver;
                    if varargin{i+1}
                        if any(strcmp('Statistics and Machine Learning Toolbox', {v.Name}))
                            non_neg = true;
                        else
                            non_neg = false;
                        end
                    end
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

% betas - non-negative or regular least squares
if non_neg
    b = lsqnonneg(X,y); % forces betas to be >= 0
else
    b = X\y; % same as inv(X'*X)*(X'*y), but left division is slightly faster and more accurate than inv()
end

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
stat.beta = b;
stat.r2 = r2;
stat.F = F;
stat.tvals = tvals;
stat.pvals = pvals;
stat.SEb = SEb;
stat.Cov = C;
stat.yhat = yhat;
stat.resid = e;

% contrasts, if any, and their associated stats. These are Wald statistics.
% Wald follows F or X^2 distribution. F stat = T^2. Student T statistic is
% related to Wald W and F as follows: T^2 = W = F.
if is_contrast
    % check that contrast weights sum to zero (centered)
    if any(sum(conmat,2) ~= 0)
        warning('Contrast row weights do not sum to zero!');
    end
    for ii = 1:size(conmat,1)
        con_est = conmat(ii,:)*stat.beta;
        contrast.tvals(ii) = ...
            sign(con_est) * sqrt(con_est'*inv(conmat(ii,:)*stat.Cov*conmat(ii,:)')*con_est);
        contrast.pvals(ii) = ...
            betainc(df_resid/(df_resid+(contrast.tvals(ii)^2)),0.5*df_resid,0.5);
    end
    stat.contrast = contrast;
end

end % end of function