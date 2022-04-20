% Purpose:  to compute the scalp coupling index, a metric of cross-correlation between the two wavelengths for each fnirs channel.
% Author:   Don Rojas, Ph.D. 
% Citation. Pollonini, L. (2014). Auditory cortex activation to natural speech and simulated cochlear implant speech measured with functional near-infrared spectroscopy,
%           Hearing Research, Volume 309,Pages 84-93
% Inputs:   1) hdr, from nirx_read_hdr
%           2) data, 2 wl x n timepoint x n channel array of raw optical
%              density data, from nirx_read_wl
%           3) threshold, scalar from 0-1 indicating xcorr threshold for
%              rejecting a channel
% Outputs:  1) bad, list of bad channels
%           2) sci, n channel vector of sci metrics
%           3) bpm_lo, low end of heart rate sci is sensitive to
%           4) bpm_hi, high end of heart rate sci is sensitive to
% History: 04/02/2022 - first working version
%          04/07/2022 - added option to change threshold on sci

function [bad, sci, bpm_lo, bpm_hi] = nirx_signal_quality_sci(hdr,data,varargin)

% defaults
lo_cut = 0.5; % lo and high cutoffs, designed to emphasize cardiac artifacts
hi_cut = 2; % in Hz
min_hi = 1.5;
bpm_lo = 60/(1/lo_cut);
if nargin > 2
    threshold = varargin{1};
else
    threshold = 0.75;
end

% extract wl data
od760 = squeeze(data(1,:,:))';
od850 = squeeze(data(2,:,:))';

% high pass filter
od760f = nirx_filter(od760,hdr,'high',lo_cut);
od850f = nirx_filter(od850,hdr,'high',lo_cut);

% low pass at either desired 2.5 Hz or what is allowable by Niquist. If
% Niquist < 1.5 do not highpass data, just let anti-alias be enough
nfft = hdr.sr/2;
if nfft >= hi_cut
    od760f = nirx_filter(od760f,hdr,'low',hi_cut);
    od850f = nirx_filter(od850f,hdr,'low',hi_cut);
    bpm_hi = 60/(1/hi_cut);
elseif nfft < hi_cut && nfft >= min_hi
    od760f = nirx_filter(od760f,hdr,'low',min_hi);
    od850f = nirx_filter(od850f,hdr,'low',min_hi);
    bpm_hi = 60/(1/hi_cut);
else
    bpm_hi = 60/(1/hdr.sr); % no high pass filter
end

% zero-lag cross correlation
od760f = od760f';
od850f = od850f';
for ii = 1:size(od760f,2)
    sci(ii) = xcorr(od760f(:,ii),od850f(:,ii),0,'coeff');
end

% reporting
bad = find(sci < threshold);
fprintf('Filter settings correspond to heart rate of %d and %d bpm\n',...
    floor(bpm_lo),floor(bpm_hi));
if ~isempty(bad)
    fprintf('The following channels may be bad at SCI < .75:\n');
    for ii=1:length(bad)
        fprintf('%d\n',bad(ii));
    end
else
    fprintf('All channels have SCI >= .75!\n');
end
