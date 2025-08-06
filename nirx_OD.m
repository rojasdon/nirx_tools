% PURPOSE:  function to compute optical density from raw signal voltages (intensity)
% AUTHOR:   D. Rojas
% INPUTS:   raw, nchan x npoints x n wavelengths matrix (see nirx_read_wl.m)
% OUTPUTS:  od, optical density
% CITATION: Strangman et al. (2003). Factors affecting the accuracy 
%           of near-infrared spectroscopy concentration calculations for 
%           focal changes in oxygenation parameters Neuroimage, 4, 865-879.
% HISTORY:  07/08/2022 - first created
%           08/06/2025 - bugfix for negative intensities
% SEE ALSO: nirx_DPF, nirx_ecoeff, nirx_MBLL
function od = nirx_OD(raw)

s = size(raw);
nwl = s(1);
npoints = s(2);
nchan = s(3);
od = zeros(nwl,npoints,nchan);
for wl = 1:nwl
    tmp = squeeze(raw(wl,:,:));
    m = repmat(mean(tmp),npoints,1);
    od(wl,:,:) = real(-log(tmp./m));
end