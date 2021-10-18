function [a,b,r2,tval,pval,ypred]=linregr(x,y,varargin)
% Author: Don Rojas, Ph.D.
% Function to calculate regression, returns a, b, r^2, pval and any misc
% predictors you want to predict values for from Eq: Y = a + bX
% inputs:   1) x and y must be vectors of same size
%           2) varargin{1} optional vector of x vals to return predicted
%              values of y for
%           3) varargin{2}, set to 1 if you want to plot data
% outputs:  1) a and b are intercept and slope
%           2) r2 is r-squared
%           3) tval is t-statistic (beta / standard error of beta)
%           3) pval is significance value, two-tailed
%           4) ypred is vector of predicted values from input #2 above

% todo: can easily extend to mult linear regression by either vectorizing
% x1...xn and y1...yn or brute forcing via for loop. Changes would need to
% occur in basic equation, calculations of b, a and yest variables.

% calc basic equation
n = length(x);
b = (n*sum(x.*y)-sum(x)*sum(y))/(n*sum(x.^2)-(sum(x))^2);
a = mean(y)-b*mean(x);

% coeff of determination
yest = a + x.*b;
SSe  = sum((y-yest).^2); % residual SS
ybar = mean(y);
SSt  = sum((y-ybar).^2); % total SS
r2   = 1 - (SSe/SSt);

% significance of slope using t-score and incomplete beta function
df_model   = 2;
df_resid   = n - df_model;
SEb  = sqrt(SSe/df_resid)/sqrt(sum((x - mean(x)).^2)); % SE of slope
tval = b/SEb;
pval = betainc(df_resid/(df_resid+(tval^2)),0.5*df_resid,0.5);

% calc predicted values
if nargin>2 && ~isempty(varargin{1})
    x2pred = varargin{1};
    ypred = a + x2pred.*b;
else
    ypred = a + b * x;
end

% plot regression stuff if wanted
if nargin>3 && varargin{2} == 1
   figure; hold on;
   plot(x,a+b*x,'g','linewidth',4);
   scatter(x,y,'bo');
   % plot(x2pred,ypred,'r.'); % uncomment to plot predicted values of y for
   % x
end

end % end of function