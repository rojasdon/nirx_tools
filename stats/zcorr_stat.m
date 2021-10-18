function zstat=zcorr_stat(z,n)
% computes z-statistic on difference between two z-scores, where z = 1 x 2
% zscores and n = 1 x 2 element n
    if numel(z) ~= 2 | numel(n) ~= 2
        error('Z and N inputs must be 2 element vectors');
    else
        zstat=(z(1)-z(2))/sqrt((1/(n(1)-3)+(1/(n(2)-3))));
    end
end