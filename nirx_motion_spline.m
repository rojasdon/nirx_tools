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
minWin = .3; % min and max segment lengths used for offset corrections, in sec
maxWin = 3; 
minWin = ceil(minWin * hdr.sr); % min and max segment lengths converted to samples
maxWin = ceil(maxWin * hdr.sr);

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
    T_artifacts = [0 diff(T_artifacts) 0]; % turns onsets into 1 and offsets into -1
    T_artifacts(end) = []; % chop added index off - it was added to prevent last index problems on start without stop
    
    % find the start and stop indices of the artifact segments
    artifact_starts = find(T_artifacts == 1);
    artifact_stops = find(T_artifacts == -1);
    if artifact_starts(end) > artifact_stops(end)
        artifact_stops = [artifact_stops length(T_artifacts)]; % start without stop -> add stop at end of data
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
    for seg=1:n_segments
        curr_seg_mean = mean(segments{seg});
        % if first sample is an artifact
        % if last sample is an artifact
        % if sample is surrounded by good data
        if seg == 1
            prev_seg_mean = mean(chandat(artifact_starts(seg)-maxWin:artifact_starts - 1));
        else
            prev_seg_mean = mean(chandat(artifact_stops(seg - 1) + 1:artifact_starts(seg) - 1));
        end
        cdata(chn,artifact_starts(seg):artifact_stops(seg)) = ...
            corrected_segments{seg} - curr_seg_mean + prev_seg_mean;
    end

end