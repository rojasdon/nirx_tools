function q = nirx_signal_quality(hdr,data,varargin)
% PURPOSE: NIRx signal quality metric, same as calculated at calibration,
%          but on specified data input to function
% AUTHOR: Don Rojas, Ph.D.
% INPUT:
%   hdr = header structure, from nirx_read_hdr.m
%   data = raw data, from nirx_read_wl.m
% OPTIONAL (arg pairs):
%   method = method to report on bad channels in command window output.
%       Does not affect q structure
%   threshold = threshold for bad channels, affects method chosen
%   window = [min max], in seconds, window to compute measures on. Must be
%       less than or equal to maximum time (default). Does not affect NIRx
%       measure, which is taken from calibration sample.
% OUTPUT:
%   q, a structure containing the following components:
%   q.quality = quality metric, comparable to the color coding in NIRStar
%             14.3 (see manual, section 8.1). Incorporates all other
%             measures except Dark Noise. 0 = lost, 1 = Critical, 2 =
%             acceptable, 3 = excellent
%   q.nirx = min(q.quality) for each channel (i.e., worst wavelength)
%   q.bad = list of bad channels, but with no details, derived from q.quality
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
% 10/10/2024 - optional input to compute metrics on specific time window in
%              data, enter in units of seconds [first last]

% defaults
method = 'NIRX'; % SCI, AI, or CV also valid
threshold = 1;
nsamp = size(data,2);
time = [0:nsamp-1]*(1/hdr.sr);
timewin = [time(1) time(end)]; % default to analyze entire sample

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
                case 'window'
                    tmp = varargin{i+1};
                    [~, t0] = min(abs(time - tmp(1)));
                    [~, t1] = min(abs(time - tmp(2)));
                    timewin = [t0 t1];
                otherwise
                    error('Invalid option!');
            end
        end
    end
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

% lowest of 3 quality indicators is the metric per channel
q.quality = zeros(length(wl),hdr.nchan);
for wl = 1:length(hdr.wl)
    for chn = 1:hdr.nchan
        q.quality(wl,chn) = min(quality{wl,chn});
    end
end
q.nirx = min(q.quality); % lower wl quality is the overall nirx metric
q.bad = find(q.nirx <= threshold)'; % called bad by NIRx standards