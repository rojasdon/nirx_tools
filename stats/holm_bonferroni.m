function [corrected, mask] = holm_bonferroni(p,alpha)
% Don Rojas, Ph.D., Colorado State University
% usage: [corrected, mask] = holm_bonferroni(p,alpha)

% Apply Holm-Bonferroni sequential correction
[sorted_p, p_index] = sort(p);
N                   = length(sorted_p);
ntests              = N-(1:N)+1;
critvals            = repmat(alpha,1,N)./ntests;
corr_ind            = sorted_p < critvals;
corrected           = p(p_index(corr_ind));
mask                = zeros(1,N);

% mask of ones to indicate significant p in order of input array of p
% values
mask(p_index(corr_ind)) = 1;

end