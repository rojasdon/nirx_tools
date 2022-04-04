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
% NOTES/TODO: if first sample is an artifact, probably cannot determine
%   because of moving stdev. Maybe run it backwards on first N samples?
%   need to add first/last segment processing
function cdata = nirx_motion_spline(data,hdr,varargin)

% defaults
p = .99; % default "splinyness" of the cubic spline, where 0 = straight line
t = 1.5; % units of standard deviation default threshold
win = ceil(hdr.sr * 9);
if mod(win,2) == 1
    win = win + 1; % ensures an odd number
end
Tset = 0;
min_art_len = ceil(hdr.sr); % minimum artifact length
if min_art_len < 2
    min_art_len = 2;
end

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

    % deal with artifact lengths that are too short
    ind = repmat(T_artifacts',1,3)+repmat(-1:1,length(T_artifacts),1);
    %if ~isempty(ind)
    %    ind = unique(ind);
    %    not_in_timeline = ind < 1 | ind > length(T_artifacts);
    %    ind(not_in_timeline) = [];
    %    T_artifacts(ind) = 1;
    %end
    ind = strfind(T_artifacts,[1 0 1]);
    for ii = 1:length(ind)
        T_artifacts(ind:ind+2) = [1 1 1];
    end
    ind = strfind(T_artifacts,[0 1 0]);
    for ii = 1:length(ind)
        T_artifacts(ind:ind+2) = [0 0 0];
    end

    % artifact indices and run lengths
    art_indices = find(diff(T_artifacts)) + 1;
    if mod(art_indices,2) % is odd
        art_indices = [art_indices length(T_artifacts)];
    end
    run_lengths = diff([1 art_indices]);
    ind = find(run_lengths < 2);
    if ~isempty(ind)
        bad_ind = [];
        for ii = 1:length(ind)
            bad_ind = [bad_ind ind(ii) - 1:ind(ii)];
        end
        art_indices(bad_ind) = [];
        run_lengths = diff([1 art_indices]);
    end
    
    % starts and stops
    artifact_starts = art_indices(1:2:end);
    artifact_stops = art_indices(2:2:end)-1;
    if artifact_starts(1) < 1
        artifact_starts(1) = 1;
    end
    if artifact_starts(end) > artifact_stops(end)
        artifact_stops = [artifact_stops length(T_artifacts)]; % start without stop -> add stop at end of data
    end
    if artifact_stops(end) > length(chandat)
        artifact_stops(end) = length(chandat);
    end
    if length(artifact_starts) > length(artifact_stops)
        artifact_starts(end) = [];
    elseif length(artifact_stops) > length(artifact_starts)
        artifact_stops(end) = [];
    end
    if artifact_stops(end) == artifact_starts(end)
        artifact_starts(end) = [];
        artifact_stops(end) = [];
    end

    % non-artifact-segments
    no_artifact_starts = artifact_stops + 1;
    no_artifact_stops = artifact_starts - 1;
    if artifact_starts(1) > 1
        no_artifact_starts = [1 no_artifact_starts]; % beginning is not an artifact
        first_segment_is_artifact = false;
    elseif artifact_starts(1) < 1
        artifact_starts(1) = 1;
        first_segment_is_artifact = true;
    else
        first_segment_is_artifact = true;
    end
    if no_artifact_stops(end) < length(chandat)
        no_artifact_stops = [no_artifact_stops length(chandat)]; % end is not an artifact
    elseif no_artifact_stops(end) > length(chandat)
        no_artifact_stops(end) = length(chandat);
    end

    n_art_segments = length(artifact_starts);
    n_noart_segments = length(no_artifact_starts);
    
    % segment the motion artifacts into discrete segments
    art_segments = cell(n_art_segments,1);
    for seg=1:n_art_segments
        art_segments{seg} = chandat(artifact_starts(seg):artifact_stops(seg));
    end

    % segment non motion artifact pieces into discrete segments
    noart_segments = cell(n_noart_segments,1);
    for seg=1:n_noart_segments
        noart_segments{seg} = chandat(no_artifact_starts(seg):no_artifact_stops(seg));
    end
    
    % model with spline interpolation
    corrected_segments = cell(n_art_segments,1);
    spline_seg = cell(n_art_segments,1);
    for seg=1:n_art_segments
        fprintf('Segment %d spline\n',seg);
        % spline model
        splineSeg{seg} = csaps(1:length(art_segments{seg}),art_segments{seg},p,1:length(art_segments{seg}));
         % subtract model from artifact segments
        corrected_segments{seg} = (art_segments{seg} - splineSeg{seg});
    end

    % stitch the non artifact and artifact segments together in same cell
    % to make next part easier
    all_segments = [];
    is_artifact = [];
    nseg = min([length(art_segments) length(noart_segments)]);
    if ~first_segment_is_artifact    
        for ii=1:nseg
            all_segments = [all_segments;noart_segments(ii);corrected_segments(ii)];
            is_artifact = [is_artifact;0;1];
        end
    else
        for ii=1:nseg
            all_segments = [all_segments;art_segments(ii);corrected_segments(ii)];
            is_artifact = [is_artifact;1;0];
        end
    end

    % add last segment if different numbers for each type
    if length(noart_segments) > length(art_segments)
        all_segments = [all_segments; noart_segments(length(noart_segments))];
        is_artifact = [is_artifact;0];
    elseif length(noart_segments) < length(art_segments)
        all_segments = [all_segments; corrected_segments(length(art_segments))];
        is_artifact = [is_artifact;1];
    end
    
    % apply correction to waveform segments, scaling as appropriate
    % 2.2.6 Table 1 scaling from Scholkmann here to avoid level 
    % problems caused by subtraction of the spline model from the artifact segments - 
    % i.e., 9 cases considered, calculating alpha and beta based
    % on time and sampling rates. Note that lambda2 in the table is the
    % length of the previous segment, lambda1 is length of current segment,
    % see Table 1 for other nomenclature
    n_segments = length(all_segments);
    level_corrected = [all_segments{1}];
    for seg=2:n_segments
        fprintf('Segment: %d\n',seg);
        lambda1 = length(all_segments{seg - 1});
        lambda2 = length(all_segments{seg});

        % length of segments to take means
        if lambda1 < minWin
                lastseglen = length(all_segments{seg - 1});
        elseif lambda1 < maxWin
            lastseglen = minWin;
        else
            lastseglen = ceil(length(all_segments{seg - 1})/10); % theta 1 in table
        end
        if lambda2 < minWin
            currsegwin = length(all_segments{seg});
        elseif lambda2 < maxWin
            currsegwin = minWin;
        else
            currsegwin = ceil(length(all_segments{seg})/10); % theta 2 in table
        end
        
        % mean of current and prior windows for level adjustment
        if lambda1 == 1
            mean_last_seg = mean(all_segments{seg - 1});
        elseif lambda1 == 2 && lastseglen >= 2
            mean_last_seg = mean(all_segments{seg - 1});
        else
            mean_last_seg = mean(all_segments{seg - 1}((end - lastseglen):(end)));
        end
        if lambda2 == 1
            mean_curr_seg = mean(all_segments{seg});
        else
            mean_curr_seg = mean(all_segments{seg}(1:currsegwin));
        end
        all_segments{seg} = all_segments{seg} - mean_curr_seg + mean_last_seg;
    end
    level_corrected = [];
    for seg = 1:n_segments
        level_corrected = [level_corrected all_segments{seg}];
    end
    cdata(chn,:) = level_corrected;
end