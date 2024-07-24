% Purpose:  to compute the scalp coupling index, a metric of cross-correlation between the two wavelengths for each fnirs channel.
% Author:   Don Rojas, Ph.D. 
% Citation. Ferdinando, Hany, et al. 
%           Implementation of a real-time fNIRS signal quality assessment.
%           Dynamics and Fluctuations in Biomedical Photonics XXI. Vol. 12841. SPIE, 2024.
% Inputs:   1) hdr, from nirx_read_hdr
%           2) data, 2 wl x n timepoint x n channel array of raw optical
%              density data, from nirx_read_wl
% Optional Input (must come in option/arg pairs)
%           1) 'threshold'|threshold, scalar from 0-1 indicating xcorr threshold for
%              rejecting a channel
%           2) 'samples'|samples, vector of samples to include, must be <=
%              max samples in timeseries
% Outputs:  1) bad, list of bad channels
%           2) sqi, index

function sqi = nirx_sqi(raw,hdr)

% calculate power spectrum
[nwl,npoints,nchan] = size(raw);
Fs = hdr.sr;
f = (0:npoints-1) * (Fs/npoints); % all frequencies
[~,lo_ind] = min(abs(f - 0.6)); % lowest cardiac signal
[~,hi_ind] = min(abs(f - 3)); % highest cardiac signal, max if < 3
% NOTE: correct this to conform to half spectrum hi end
f = f(lo_ind:hi_ind);

Y = zeros(nwl,length(f),nchan);
max_power = zeros(nwl,nchan);
mean_power = zeros(nwl,nchan);
sqi_pow = zeros(nwl,nchan);
sqi_skew = zeros(nwl,nchan);
sqi_kurt = zeros(nwl,nchan);
sqi = zeros(nwl,nchan);
for wl = 1:nwl
    for chan = 1:nchan
        tmp = abs(2*fft(squeeze(raw(wl,lo_ind:hi_ind,chan)))/n);
        max_power(wl,chan) = max(tmp);
        mean_power(wl,chan) = mean(tmp);
        sqi_pow(wl,chan) = max_power(wl,chan)/mean_power(wl,chan);
        sqi_skew(wl,chan) = skewness(tmp);
        sqi_kurt(wl,chan) = kurtosis(tmp);
        sqi(wl,chan) = sqi_pow(wl,chan)/(sqi_skew(wl,chan) + sqi_kurt(wl,chan));
        Y(wl,:,chan) = tmp; % just store half spectrum
    end
end

% ratio calculation

end