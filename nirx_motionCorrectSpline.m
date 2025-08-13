function x_corr = motionCorrectSpline(x, t, sdWindow, p_spline)
% motionCorrectSpline  Applies Scholkmann spline-based motion correction.
%
% Inputs:
%   x          - vector of fNIRS signal (time × 1)
%   t          - corresponding time vector (same length)
%   sdWindow   - window size (in samples) for moving STD
%   sdThresh   - threshold (e.g. multiples of baseline SD) for detecting motion
%   p_spline   - smoothing parameter: 1 = natural cubic spline, 0 = linear
%
% Output:
%   x_corr     - corrected signal vector

n = length(x);
% Compute moving standard deviation

movSD = movstd(x, sdWindow);
sdThresh = 2*median(movSD);

% Detect motion artifact indices
artifact = movSD > sdThresh;

% Expand artifact regions to contiguous segments
d = diff([0; artifact; 0]);
startIdx = find(d == 1);
endIdx   = find(d == -1) - 1;

x_corr = x;  % initialize corrected signal

% Identify normal (artifact-free) segments
goodIdx = ~artifact;
t_good = t(goodIdx);
x_good = x(goodIdx);

% Build smoothing spline model using good data
splineFit = csaps(t_good, x_good, p_spline);

% Replace artifacted samples with spline interpolation
for k = 1:numel(startIdx)
    idx_range = startIdx(k):endIdx(k);
    x_corr(idx_range) = fnval(splineFit, t(idx_range));
end

end