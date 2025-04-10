function [chpos,chlbl] = nirx_compute_chanlocs(lbl,pos,chns,short_indices)
% PURPOSE: function computes midpoints between two optodes 
%   as channel locations.
% INPUTS:
%   lbl = 1 x n string array of generic optode labels, "S1"..."Sn",
%         "D1"..."Dn", e.g., from nirx_read_optpos.m
%   pos = n x 3 array of positions, from nirx_read_optpos.m
%   chns = n x 2 array of channel definitions from nirx_read_chconfig.m chn(:,2:3), or
%          from nirx_read_hdr.m .SDpairs
%   short_indices = 1 x n array of short detector indices from
%                   nirx_read_hdr.m = hdr.shortSDindices
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

% first sort sensors and detectors
sources = find(lbl.contains("S"));
detectors = find(lbl.contains("D"));
Spos = pos(sources,:);
Dpos = pos(detectors,:);
SDpos = pos(short_indices,:);

% now find midpoint locations for the long channels
nchan = length(chns);
longpos = zeros(nchan,3) - length(short_indices);
for ii = 1:nchan
    if ismember(short_indices,chns(ii,2))
        continue;
    else
        chpair = chns(ii,:);
        source_ind = find(ismember(1:length(sources),chpair(1)));
        det_ind = find(ismember(1:length(detectors),chpair(2)));
        Sloc = Spos(source_ind,:);
        Dloc = Dpos(det_ind,:);
        longpos(ii,:) = (Sloc + Dloc)./2;
    end
end
% NOTE: short channel locations need computation offset of 8 mm from source
% location. So, probably feed hdr.shortSDpairs to function to get source
% locs, then do 8 mm offset in some direction prob +x (to right).

shortpos = SDpos; % just use the detector locations since co-located on detectors
% all channels
chpos = [longpos;shortpos];
chlbl = [repmat("L",1,length(longpos))+string(1:length(longpos)) repmat("S",1,length(shortpos))+string(1:length(shortpos))]';