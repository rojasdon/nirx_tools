% Purpose:  to compute the scalp coupling index, a metric of cross-correlation between the two wavelengths for each fnirs channel.
% Author:   Don Rojas, Ph.D. 
% Citation. Pollonini, L. (2014). Auditory cortex activation to natural speech and simulated cochlear implant speech measured with functional near-infrared spectroscopy,
%           Hearing Research, Volume 309,Pages 84-93
% Inputs:   1) hdr, from nirx_read_hdr
%           2) data, 2 wl x n timepoint x n channel array of raw optical
%              density data, from nirx_read_wl
% Optional Input (must come in option/arg pairs)
%           1) 'threshold'|threshold, scalar from 0-1 indicating xcorr threshold for
%              rejecting a channel
%           2) 'samples'|samples, vector of samples to include, must be <=
%              max samples in timeseries
% Outputs:  1) bad, list of bad channels
%           2) sci, n channel vector of sci metrics
%           3) bpm_lo, low end of heart rate sci is sensitive to
%           4) bpm_hi, high end of heart rate sci is sensitive to
% Examples: 1) [bad, sci] = nirx_signal_quality_sci(hdr,data);
%           2) [bad, sci] = nirx_signal_quality_sci(hdr,data,'threshold',.5);
%           3) [bad, sci] = nirx_signal_quality_sci(hdr,data','samples',1:1000];
% Notes:    1) Sampling rates should likely be minimum of 3 Hz to
%              adequately capture normal heart rates. SCI will not be as
%              effective for lower SR.
%           2) Lower frequency (longer wavelength) IR shows much less
%              cardiac signal than higher frequency. < 700 nm weigted to
%              deoxy-hemoglobin signal and may not have much cardiac
%              signal.
%           3) Appropriate SCI thresholds will differ based on different
%              hardware, especially given different emitter frequencies.
%              Use caution when adopting threshold from prior studies.
%              E.g., see Polloni et al. 2016 Phoebe article.
% History: 04/02/2022 - first working version
%          04/07/2022 - added option to change threshold on sci
%          06/16/2022 - added in time point argument 
%          07/20/2024 - fixed some reporting issues regarding beats per
%                       minute measures for low sample rates, added more
%                       input options to override defaults, changed name to
%                       nirx_sci.m

function [bad, sci, bpm_lo, bpm_hi, od] = nirx_sci(hdr,data,varargin)

% defaults
lo_cut = 0.5; % lo and high cutoffs, designed to emphasize cardiac artifacts
hi_cut = 2; % in Hz
min_hi = 1.5;
bpm_lo = 60/(1/lo_cut);
threshold = .3; % default. From PHOEBE paper, .23
sample_indices = 1:size(data,2); % default is all samples

% check/process input arguments
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for i=1:2:optargin
            switch varargin{i}
                case 'threshold'
                    threshold = varargin{i+1};
                case 'samples'
                    sample_indices = varargin{i+1};
                case 'lo_cut'
                    lo_cut = varargin{i+1};
                case 'hi_cut'
                    hi_cut = varargin{i+1};
                case 'samples'
                    sample_indices = varargin{i+1};
                otherwise
                    error('Invalid option!');
            end
        end
    end
end

% extract wl data
od760 = squeeze(data(1,sample_indices,:))';
od850 = squeeze(data(2,sample_indices,:))';

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
    bpm_hi = 60/(1/nfft);
else
    bpm_hi = 60/(1/nfft); % no high pass filter
end

% normalization (not needed with xcorr option 'coeff'
% xbar_lo = repmat(mean(od760f,2),1,length(od760f)); % channel means
% sd_lo = repmat(std(od760f,[],2),1,length(od760f)); % channel sdev
% xbar_hi = repmat(mean(od850f,2),1,length(od850f));
% sd_hi = repmat(std(od850f,[],2),1,length(od850f));
% od760f = (od760f - xbar_lo)./sd_lo;
% od850f = (od850f - xbar_hi)./sd_hi;

% od for output
od = zeros(size(data));
od(1,:,:) = od760f';
od(2,:,:) = od850f';

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
    fprintf('The following channels may be bad at SCI < %.2f:\n',threshold);
    for ii=1:length(bad)
        fprintf('%d\n',bad(ii));
    end
else
    fprintf('All channels have SCI >= .75!\n');
end
