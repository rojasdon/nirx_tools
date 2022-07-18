function [q,bad] = nirx_signal_quality(hdr,data)
% PURPOSE: output of various metrics used to evaluate signal quality
% AUTHOR: Don Rojas, Ph.D.
% INPUT:
%   hdr = header structure, from nirx_read_hdr.m
%   data = raw data, from nirx_read_wl.m
% OUTPUT:
%   q, a structure containing the following components:
%   q.quality = quality metric, comparable to the color coding in NIRStar
%             14.3 (see manual, section 8.1). Incorporates all other
%             measures except Dark Noise. 0 = lost, 1 = Critical, 2 =
%             acceptable, 3 = excellent
%   q.level = average signal levels per wavelength and channel
%   q.gain = channel gains
%   q.noise = coefficient of variation on q.level per channel and wl
%   q.dn = dark noise, measured on detectors
%   bad = list of bad channels, but with no details, derived from q.
% SEE ALSO: NIRStar manual section 8.1 and Table 2 for interpretations

% Revision history:
% 03/04/2022 - added text output to show bad channels, if any
% 03/13/2022 - added optional bad channel output for convenient list of bad
%              channels
% 03/31/2022 - added q channel info for convenience

% calculate level and noise measures
q.level = squeeze(mean(data,2));
dev = squeeze(std(data,[],2));
q.noise = (dev./q.level)*100;
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

% find/report questionable channels
[wl_ind,bad] = ind2sub(size(q.quality),find(q.quality <= 1));
bad = unique(bad); % it only takes one bad wavelength
if ~isempty(bad)
    fprintf('The following channels are likely bad:\n');
    for ii=1:length(bad)
        fprintf('Channel: %d\n',bad(ii));
    end
else
    fprintf('All channels pass quality metrics.\n');
end
q.shortchans = hdr.shortSDindices;
q.longchans = hdr.longSDindices;
q.SDpairs = hdr.SDpairs;
q.bad = bad; % called bad by NIRx standards