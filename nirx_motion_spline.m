% PURPOSE: to reduce/remove motion artifact in NIRS signals using a moving
%   average, cubic spline approach, as described in the citation below. The
%   approach is also sometimes called MARA (motion artifact reduction algorithm).
% AUTHOR: Don Rojas, Ph.D.
% CITATION: Scholkmann et al. (2010). How to detect and reduce movement artifacts 
%   in near-infrared imaging using moving standard deviation and spline interpolation. 
%   Physiological Measurement, 31(5):649-662.
% INPUTS:
%   data, N channel x N timepoint nirs timeseries
%   hdr, from nirx_read_header.m
%   p, spline interpolation degree, from 0 (linear fit), to 1 (full
%       spline). From Scholkmann, the best choice is .01 (pg.6)
%   t, threshold, in units relevant to input data scale (default will be
%       set based on mean +/- 2 * stdev, but authors recommend empirical
%       choice
%   win, time window over which to calculate the moving standard deviation
%       default = 3s
% OUTPUT:
%   cdata, N channel x N timepoint nirs timeseries, motion corrected
function cdata = nirx_motion_spline(data,hdr,varargin)

% defaults
p = .99; % default "splinyness" of the cubic spline, where 0 = straight line
t = 1.5; % units of standard deviation default threshold
win = ceil(hdr.sr * 9);
if mod(win,2) == 1
    win = win + 1; % ensures an odd number
end
Tset = 0;

% this is alpha and beta in Table 1, aka min (alpha) and max (beta) window lengths
minWin = ceil(1/3 * hdr.sr); % min and max segment lengths, in samples
maxWin = ceil(2 * hdr.sr); % from .33 to 2x the sample rate, rounded up

% parse input and set default options
if nargin < 2
    error('Must supply at least 2 arguments to function!');
else
    if ~isempty(varargin)
        optargin = size(varargin,2);
        if (mod(optargin,2) ~= 0)
            error('Optional arguments must come in option/value pairs');
        else
            for i=1:2:optargin
                switch lower(varargin{i})
                    case 'p'
                        p = varargin{i+1};
                    case 't'
                        thresh = varargin{i+1};
                        Tset = 1;
                    case 'win'
                        win = varargin{i+1};
                    otherwise
                        error('Invalid option!');
                end
            end
        end
    else
        % do nothing
    end
end

nchan = size(data,1);
npoints = size(data,2);
cdata = data;

% loop through channels
for chn = 1:nchan
    fprintf('Spline correction channel %d\n',chn);
    chandat = data(chn,:); % select data

    % detect artifacts with moving standard deviation
    mstd = movstd(chandat,win);
    xbar_mstd = mean(mstd);
    std_mstd = std(mstd);
    if ~Tset
        thresh = xbar_mstd + (t * std_mstd);
    end
    T_artifacts = (abs(mstd)>thresh).*mstd;
    T_artifacts(T_artifacts > 0) = 1; % set non-zero indices to 1
    T_artifacts_diff = [0 diff(T_artifacts) 0]; % turns onsets into 1 and offsets into -1
    T_artifacts_diff(end) = []; % chop added index off - it was added to prevent last index problems on start without stop
    
    % find the start and stop indices of the artifact segments
    artifact_starts = find(T_artifacts_diff == 1);
    artifact_stops = find(T_artifacts_diff == -1);
    if artifact_starts(end) > artifact_stops(end)
        artifact_stops = [artifact_stops length(T_artifacts_diff)]; % start without stop -> add stop at end of data
    end

    n_segments = length(artifact_starts);
    
    % segment the motion artifacts into discrete segments
    segments = cell(n_segments,1);
    for seg=1:n_segments
        segments{seg} = chandat(artifact_starts(seg):artifact_stops(seg));
    end
    
    % model with spline interpolation
    corrected_segments = cell(n_segments,1);
    spline_seg = cell(n_segments,1);
    for seg=1:n_segments
        % spline model
        splineSeg{seg} = csaps(1:length(segments{seg}),segments{seg},p,1:length(segments{seg}));
         % subtract model from artifact segments
        corrected_segments{seg} = (segments{seg} - splineSeg{seg});
    end
    
    
    % apply correction to waveform segments, scaling as appropriate
    % 2.2.6 Table 1 scaling from Scholkmann here to avoid level 
    % problems caused by subtraction of the spline model from the artifact segments - 
    % i.e., 9 cases considered, calculating alpha and beta based
    % on time and sampling rates. Note that lambda2 in the table is the
    % length of the previous segment, lambda1 is length of current segment,
    % see Table 1 for other nomenclature
    for seg=1:n_segments
        fprintf('Artifact %d\n',seg);
        if seg == 1 && artifact_starts(1) >= minWin
            if artifact_starts > maxWin
                a = mean(chandat(artifact_starts(seg)-maxWin-1:artifact_starts(seg)-1));
                b = mean(segments{seg});
            else
                a = mean(chandat(artifact_starts(seg)-minWin-1:artifact_starts(seg)-1));
                b = mean(segments{seg});
            end
        elseif seg == 1 && artifact_starts(1) < minWin
            a = mean(chandat(artifact_stops(seg)+1:artifact_stops(seg)+minWin));
            b = mean(segments{seg});
        else
            lambda1 = length((artifact_starts(seg) - artifact_stops(seg - 1)));
            lambda2 = length(segments{seg});
            theta1 = ceil(lambda1/10); theta2 = ceil(lambda2/10);
            if lambda2 <= minWin
                if lambda1 <= minWin
                    a = mean(chandat(artifact_stops(seg-1)+1:artifact_starts(seg)-1)); % entire prior non-artifact period
                    b = mean(segments{seg});
                elseif lambda1 > minWin && lambda1 < maxWin
                    a = mean(chandat(artifact_stops(seg-1)+1-minWin:artifact_starts(seg)-1)); % minimum window in prior non-artifact period
                    b = mean(segments{seg});
                else 
                    a = mean(chandat(artifact_stops(seg-1)+1-theta1:artifact_starts(seg)-1));
                    b = mean(segments{seg});
                end
            elseif lambda2 > minWin && lambda2 < maxWin
                if lambda1 <= minWin
                    a = mean(chandat(artifact_stops(seg-1)+1-theta1:artifact_starts(seg)-1));
                    b = mean(segments{seg}(1:minWin));
                elseif lambda1 > minWin && lambda1 < maxWin
                    a = mean(chandat(artifact_stops(seg-1)+1-minWin:artifact_starts(seg)-1)); % minimum window in prior non-artifact period
                    b = mean(segments{seg}(1:minWin));
                else 
                    a = mean(chandat(artifact_stops(seg-1)+1-theta1:artifact_starts(seg)-1));
                    b = mean(segments{seg}(1:minWin));
                end
            else
                if lambda1 <= minWin
                    a = mean(chandat(artifact_stops(seg-1)+1:artifact_starts(seg)-1)); % entire prior non-artifact period
                    b = mean(segments{seg}(1:theta2));
                elseif lambda1 > minWin && lambda1 < maxWin
                    a = mean(chandat(artifact_stops(seg-1)+1-minWin:artifact_starts(seg)-1));
                    b = mean(segments{seg}(1:theta2));
                else
                    a = mean(chandat(artifact_stops(seg-1)+1-theta1:artifact_starts(seg)-1));
                    b = mean(segments{seg}(1:theta2));
                end
            end
        end
        cdata(chn,artifact_starts(seg):artifact_stops(seg)) = ...
            corrected_segments{seg} + a - b;
    end
end