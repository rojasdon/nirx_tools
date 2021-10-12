function k = kurts(x)
% function to return kurtosis of a vector input
    xbar = mean(x);
    sd   = std(x);
    npnt = length(x);
    k    = (sum((x - xbar).^4)/npnt)/sd^4;
end