function [q,bad] = nirx_signal_quality(hdr,data,varargin)
% PURPOSE: output of various metrics used to evaluate signal quality
% AUTHOR: Don Rojas, Ph.D.
% INPUT:
%   hdr = header structure, from nirx_read_hdr.m
%   data = raw intensity data, from nirx_read_wl.m
% OUTPUT:
%   q, a structure containing the following components:
%   q.quality = quality metric, comparable to the color coding in NIRStar
%             14.3 (see manual, section 8.1). Incorporates all other
%             measures except Dark Noise. 0 = lost, 1 = Critical, 2 =
%             acceptable, 3 = excellent
%   q.level = average signal levels per wavelength and channel
%   q.gain = channel gains
%   q.noise = coefficient of variation on q.level per channel and wl. CV
%   suggested threshold is > 7.5% = bad
%   q.dn = dark noise, measured on detectors
%   q.sci = scalp coupling index
%   q.powi = structure containing PHOEBE power indices
%   q.autopower = power spectral peak of autocorrelation data
%   bad = list of bad channels, but with no details, derived from q.quality
% SEE ALSO: NIRStar manual section 8.1 and Table 2 for interpretations

% see also: https://opg.optica.org/abstract.cfm?URI=BRAIN-2020-BM2C.5 and
% Coefficient of variation method -
% https://www.mdpi.com/2076-3417/12/1/316#sec2dot4-applsci-12-00316
% equation 6.

% Revision history:
% 03/04/2022 - added text output to show bad channels, if any
% 03/13/2022 - added optional bad channel output for convenient list of bad
%              channels
% 03/31/2022 - added q channel info for convenience
% 04/20/2024 - incorporated SCI, autocorr spectrum and Cui methods
% 08/11/2024 - optional input to determine method for calling channels bad
%              for output

% defaults
method = 'NIRX'; % SCI, AI, or CV also valid
nirx_threshold = 1;
sci_threshold = .8;
ai_threshold = .1;
cv_threshold = 7.5;

% check/process input arguments
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for i=1:2:optargin
            switch varargin{i}
                case 'method'
                    method = varargin{i+1};
                case 'threshold'
                    threshold = varargin{i+1};
                otherwise
                    error('Invalid option!');
            end
        end
    end
end
switch method
    case "NIRx"
        nirx_threshold = threshold;
    case "SCI"
        sci_threshold = threshold;
    case "AI"
        ai_threshold = threshold;
    case "CV"
        cv_threshold = threshold;
end

% calculate level and noise measures
q.level = squeeze(mean(data,2));
dev = squeeze(std(data,[],2));
q.noise = (dev./q.level)*100;
q.cv = max(q.noise); % worst wavelength is used for threshold
q.gain = hdr.gains(hdr.maskind); % only channels in mask
q.dn = hdr.DarkNoise;

% calculate the quality metric per manual
quality = cell(length(hdr.wl),hdr.nchan);
for wl = 1:length(hdr.wl)
    for chn = 1:hdr.nchan
        % gain criteria
        switch q.gain(chn)
            case {0, 8}
                quality{wl,chn} = [quality{wl,chn} 1];
            case 7
                quality{wl,chn} = [quality{wl,chn} 2];
            case {1,2,3,4,5,6}
                quality{wl,chn} = [quality{wl,chn} 3];
            otherwise
                quality{wl,chn} = [quality{wl,chn} 0];
        end
        % level criteria
        if q.level(wl,chn) < .01
            quality{wl,chn} = [quality{wl,chn} 0];
        elseif q.level(wl,chn)  >= .01 && q.level(wl,chn)  <= .03
            quality{wl,chn} = [quality{wl,chn} 1];
        elseif q.level(wl,chn)  > .03 && q.level(wl,chn)  <= .09
            quality{wl,chn} = [quality{wl,chn} 2];
        elseif q.level(wl,chn)  > .09 && q.level(wl,chn)  <= 1.4
            quality{wl,chn} = [quality{wl,chn} 3];
        elseif q.level(wl,chn)  > 2.5
            quality{wl,chn} = [quality{wl,chn} 1];
        end
        % noise criteria
        if q.noise(wl,chn) > 7.5
            quality{wl,chn} = [quality{wl,chn} 1];
        elseif q.noise(wl,chn)  < 7.5 && q.noise(wl,chn) >= 2.5
            quality{wl,chn} = [quality{wl,chn} 2];
        elseif q.noise(wl,chn) < 2.5
            quality{wl,chn} = [quality{wl,chn} 3];
        end
    end
end

% lowest of 3 quality measures is the metric per channel
q.quality = zeros(length(wl),hdr.nchan);
for wl = 1:length(hdr.wl)
    for chn = 1:hdr.nchan
        q.quality(wl,chn) = min(quality{wl,chn});
    end
end
q.nirx = min(q.quality); % lower wl quality is the nirx metric

% SCI and power index
[~, q.sci, q.powi,~, ~] = nirx_sci(hdr,data);

% find/report questionable channels
q.shortchans = hdr.shortSDindices;
q.longchans = hdr.longSDindices;
q.SDpairs = hdr.SDpairs;
q.nirx_bad = find(q.nirx <= nirx_threshold)'; % called bad by NIRx standards
q.sci_bad = find(q.sci < sci_threshold)';
q.ai_bad = find(q.powi.powi < ai_threshold)';
q.cv_bad = find(q.cv > cv_threshold)';
bad = eval(['q.' method '_bad']);
if ~isempty(bad)
    fprintf('The following channels are likely bad using %s criteria and threshold = %.1f:\n',...
        method,threshold);
    for ii=1:length(bad)
        fprintf('Channel: %d\n',bad(ii));
    end
else
    fprintf('All channels pass quality metrics.\n');
end