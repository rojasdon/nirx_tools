% PURPOSE: function to compute optical density from raw signal (intensity)
% AUTHOR: D. Rojas
% INPUTS:  raw, nchan x npoints x n wavelengths matrix (see nirx_read_wl.m)
% OUTPUTS: od, optical density
% CITATION: Strangman et al. (2003). Factors affecting the accuracy 
%    of near-infrared spectroscopy concentration calculations for 
%    focal changes in oxygenation parameters Neuroimage, 4, 865-879.
% HISTORY: 07/08/2022 - first created
% SEE ALSO: nirx_OD, nirx_DPF, nirx_ecoeff
function od = nirx_OD(raw)

s = size(raw);
nwl = s(1);
npoints = s(2);
nchan = s(3);
od = zeros(nwl,npoints,nchan);
for wl = 1:nwl
    tmp = squeeze(raw(wl,:,:));
    m = repmat(mean(tmp),npoints,1);
    od(wl,:,:) = -log(tmp./m);
end