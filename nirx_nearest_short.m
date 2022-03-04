% PURPOSE:  returns channel number of nearest short channel to a given long channel
% INPUTS:   longpos, n x 3 array of long channel
%           positions, from nirx_compute_chanlocs.m
%           shortpos, n x 3 array of short channel positions,
%           nirx_compute_chanlocs.m
%           hdr, header from nirx_read_hdr.m
% OUTPUTS:  scnn, short channel nearest neighbor, among all short channels,
%           nlongchan x 1
function scnn = nirx_nearest_short(shortpos,longpos,hdr)
    scnn = zeros(length(longpos),1);
    for ii=1:length(longpos)
        dist = sqrt(sum(longpos(ii,:) - shortpos,2).^2);
        [~,ind] = min(dist);
        scnn(ii) = hdr.shortSDindices(ind);
    end