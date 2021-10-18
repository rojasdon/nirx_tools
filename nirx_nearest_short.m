% PURPOSE:  returns index of nearest short channel to a given long channel
% INPUTS:   ldi, long detector index
%           nb, nchan x nchan array of channel distances, see
%           nirx_nearest_neigbors.m
%           hdr, from nirx_read_hdr.m
% OUTPUTS:  sdi, short channel index, among all channels in hdr
function sdi = nirx_nearest_short(ldi,nb,hdr)
    ld_sd_distances = nb(ldi,hdr.shortSDindices);
    [~,ind] = min(ld_sd_distances);
    sdi = hdr.shortSDindices(ind);