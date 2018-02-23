function chanpos = nirx_compute_chanlocs(ids,pos,chns)
% function computes midpoints between two optodes 
% as channel locations.
% ids = 1 x n array of generic optode labels, S1...Sn, D1...Dn
% pos = n x 3 array of positions
% chns = n x 2 array of channel definitions

% NOTE: the midpoint on a straight line isn't accurate given that the
% points lie on a surface. Some/many will be inside the head.

% first sort sensors and detectors
sind = [];
dind = [];
for ii=1:length(ids)
    if ids{ii}{1}(1)=='S'
        sind = [sind ii];
    end
end
dind = setdiff(1:length(ids),sind);
Spos = pos(sind,:);
Dpos = pos(dind,:);
clear pos;

% now find midpoint locations for the channel
nchan = length(chns);
chanpos = zeros(nchan,3);
for ii = 1:nchan
    chpair = chns(ii,2:3);
    loc1 = Spos(chpair(1),:);
    loc2 = Dpos(chpair(2),:);
    chanpos(ii,1) = (loc1(1) + loc2(1))/2;
    chanpos(ii,2) = (loc1(2) + loc2(2))/2;
    chanpos(ii,3) = (loc1(3) + loc2(3))/2;
end