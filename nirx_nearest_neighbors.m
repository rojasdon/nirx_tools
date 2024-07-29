function nb = nirx_nearest_neighbors(chanpos)
% PURPOSE: finds nearest neighbor channels
% INPUT: chanpos = n x 3 positions of channels
% OUTPUT: nb = nchan x nchan matrix of Euclidean distances
% SEE ALSO: nirx_read_optpos.m
% TODO: rename this nirx_neighbors.m and/or expand so that this function
% returns either short, long or both channels sorted by dist to detectors.
% Modify related functions as needed e.g. nirx_nearest_short.m

nchan = length(chanpos);
for ii = 1:nchan
    nb(ii,:) = sqrt(sum((chanpos(1:nchan,:) - repmat(chanpos(ii,:), nchan, 1)).^2, 2));
end