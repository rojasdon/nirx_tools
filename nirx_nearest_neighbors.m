function nb = nirx_nearest_neighbors(chanpos)
% PURPOSE: finds nearest neighbor channels
% INPUT: chanpos = n x 3 positions of channels
% OUTPUT: nb = nchan x nchan matrix of Euclidean distances
% SEE ALSO: nirx_read_optpos.m

nchan = length(chanpos);
for ii = 1:nchan
    nb(ii,:) = sqrt(sum((chanpos(1:nchan,:) - repmat(chanpos(ii,:), nchan, 1)).^2, 2));
end