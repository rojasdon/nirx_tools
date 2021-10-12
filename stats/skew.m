function s = skew(x)
% function to return Pearson's 2nd skewness coefficient for a vector input
    xbar = mean(x);
    xmed = median(x);
    sd   = std(x);
    s    = (3*(xbar-xmed))/sd;
end