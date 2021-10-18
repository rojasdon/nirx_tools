function Z = logistic(inp)
% basic logistic function for convenience
% input can be linear part of regression output from glmfit using 'logit'
% e.g., B = glmfit(X,[Y ones(nsamp,1)],'binomial','link','logit')
% then linear part is Z = B(1) + X * (B(2)) and logistic is:
% Z = logistic(Z)

Z= 1 ./ (1 + exp(-inp));

end