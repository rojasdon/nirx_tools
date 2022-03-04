function [hbo_corr,hbr_corr,hbt_corr] = nirx_motion_cbsi(hbo,hbr)
% PURPOSE: motion correction of nirs data based on correlation based signal
% improvement method
% CITATION: Cui et al. (2009). Functional near infrared spectroscopy (NIRS) 
%   signal improvement based on negative correlation between oxygenated 
%   and deoxygenated hemoglobin dynamics. Neuroimage, 49(4), 3039-3046
% SEE ALSO: Brigadoi et al. (2014). Motion artifacts in functional near-infrared spectroscopy: 
%   a comparison of motion correction techniques applied to real cognitive
%   data. Neuroimage, 85, 181-191. (Raises concerns about use of algorithm for HbR)
% INPUTS:
%   hbo = oxy-hemoglobin signals, N channel x N timepoint array
%   hbr = deoy-hemoglobin signals, N channel x N timepoint array
% OUTPUTS:
%   hbo_corr, corrected hbo signals
%   hbr_corr, corrected hbr signals
%   hbt_corr, corrected total hemoglobin signals

S = size(hbo);
nchan = S(1);
npoints = S(2);
hbo_corr = zeros(nchan,npoints); % initialize arrays
hbr_corr = hbo_corr;
hbt_corr = hbo_corr;
for chn = 1:nchan
    oxy_h = hbo(chn,:)';
    deoxy_h = hbr(chn,:)';
    std_oxy_h = std(oxy_h); % standard deviation of timeseries
    std_deoxy_h = std(deoxy_h);
    a = std_oxy_h/std_deoxy_h; % see Eq. 2 in cited paper (alpha)
    hbo_corr(chn,:) = (.5*(oxy_h - (a*deoxy_h)))';
    hbr_corr(chn,:) = ((-1/a)*oxy_h)';
    hbt_corr(chn,:) = hbo_corr(chn,:) + hbr_corr(chn,:);
end