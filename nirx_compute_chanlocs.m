function [chpos,chlbl] = nirx_compute_chanlocs(lbl,pos,chns)
% PURPOSE: function computes midpoints between two optodes 
%   as channel locations.
% INPUTS:
%   lbl = 1 x n string array of generic optode labels, "S1"..."Sn",
%         "D1"..."Dn", e.g., from nirx_read_optpos.m
%   pos = n x 3 array of positions, from nirx_read_optpos.m
%   chns = n x 2 array of channel definitions from nirx_read_chconfig.m chn(:,2:3), or
%          from nirx_read_hdr.m .SDpairs
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
%   04/10/2025 - revision to better integrate with nirx_read_header.m and
%                nirx_compute_chanlocs.m
%   04/11/2025 - bugfix to short channel locations, removed need for short
%                indices as inputs

% first sort sensors and detectors
sources = find(lbl.contains("S"));
detectors = find(lbl.contains("D"));
Spos = pos(sources,:);
Dpos = pos(detectors,:);

% now find midpoint locations for the long channels
nchan = length(chns);
chpos = zeros(nchan,3);
for ii = 1:nchan
    chpair = chns(ii,:);
    source_ind = find(ismember(1:length(sources),chpair(1)));
    det_ind = find(ismember(1:length(detectors),chpair(2)));
    Sloc = Spos(source_ind,:);
    Dloc = Dpos(det_ind,:);
    chpos(ii,:) = (Sloc + Dloc)./2;
    chlbl(ii) = ii;
end