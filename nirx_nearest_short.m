% PURPOSE:  returns channel number of nearest short channel to a given long channel
% INPUTS:   longpos, n x 3 array of long channel
%           positions, from nirx_compute_chanlocs.m
%           shortpos, n x 3 array of short channel positions,
%           nirx_compute_chanlocs.m
%           hdr, header from nirx_read_hdr.m
%           bad, optional bad short channels to exclude (selects nearest
%           after excluding)
% OUTPUTS:  scnn, short channel nearest neighbor, among all short channels,
%           nlongchan x 1
% Revision History:
%   03/13/2022 - added optional bad short channel input to prevent them
%                from being used as the nearest short channel, for example 
%                in short channel regression

function scnn = nirx_nearest_short(shortpos,longpos,hdr,varargin)

% bad channels if any
% set bad channels to infinite so they will never be selected as nearest
if nargin > 3
    bad = varargin{1};
    bad_ind = find(ismember(hdr.shortSDindices,bad));
    shortpos(bad_ind,:) = Inf; 
end

% find nearest short for each long
scnn = zeros(length(longpos),1);
for ii=1:length(longpos)
    dist = sqrt(sum(longpos(ii,:) - shortpos,2).^2);
    [~,ind] = min(dist);
    scnn(ii) = hdr.shortSDindices(ind);
end