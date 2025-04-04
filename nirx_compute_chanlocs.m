function [chpos,chlbl] = nirx_compute_chanlocs(lbl,pos,chns,short_indices)
% PURPOSE: function computes midpoints between two optodes 
%   as channel locations.
% INPUTS:
%   lbl = 1 x n string array of generic optode labels, "S1"..."Sn",
%         "D1"..."Dn", e.g., from nirx_read_optpos.m
%   pos = n x 3 array of positions
%   chns = n x 2 array of channel definitions from nirx_read_chconfig.m chn(:,2:3), or
%          from nirx_read_hdr.m .SDpairs
%   short_indices = 1 x n array of short detector indices from
%                   nirx_read_hdr.m
% OUTPUTS:
%   chpos = 3d channel positions
%   chlbl = 3d channel labels "L1"..."Ln" for long, "S1" to "Sn" for short
% NOTE: the midpoint on a straight line isn't accurate in terms of plotting given that the
%       points lie on a surface. Some/many will be inside the head. But, this is
%       the S-D distance that is relevant to light paths, not the surface
%       distance.
% HISTORY:
%   03/01/2022 - fixed short indexing bug, returns short channel positions
%                separately from longpos
%   07/25/2024 - minor modification to increase calculation efficiency
%   08/11/2024 - rewritten for more general usage. E.g., returns all
%                channels for all pairs given, plus simple names
%   04/03/2025 - bugfixes to implement last history change correctly

% first sort sensors and detectors
sources = find(lbl.contains("S"));
detectors = find(lbl.contains("D"));
Spos = pos(sources,:);
Dpos = pos(detectors,:);
SDpos = pos(short_indices,:);
clear pos;

% now find midpoint locations for the channels
short_chan_indices = find(ismember(chns(:,2),short_indices));
nchan = size(chns,1);
long_chan_indices = setdiff(1:nchan,short_chan_indices);
nshort = length(short_chan_indices);
chpos = zeros(nchan,3);
sdind = 1;
ldind = 1;
for ii = 1:nchan
    if ismember(ii,short_chan_indices)
        chpos(ii,:) = SDpos(sdind,:);
        chlbl(ii) = "S"+string(sdind);
        sdind = sdind + 1;
    else
        chpair = chns(ii,:);
        Sloc = Spos(chpair(1),:);
        Dloc = Dpos(chpair(2),:);
        chpos(ii,:) = (Sloc + Dloc)./2;
        chlbl(ii) = "L"+string(ldind);
        ldind = ldind + 1;
    end
end