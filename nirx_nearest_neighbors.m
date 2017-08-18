function nb = nirx_nearest_neighbors(chanpos)
% finds nearest neighbor channels
% chanpos = n x 3 positions of channels
% output nb = nchan x nchan matrix of Euclidean distances

nchan = length(chanpos);
for ii = 1:nchan
    nb(ii,:) = sqrt(sum((chanpos(1:nchan,:) - repmat(chanpos(ii,:), nchan, 1)).^2, 2));
end