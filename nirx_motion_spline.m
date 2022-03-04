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
%       spline). From literature, the best choice is .99, but the original
%       citation mistakenly states .01 (pg. 6)
%   win, time window over which to calculate the moving standard deviation
% OUTPUT:
%   cdata, N channel x N timepoint nirs timeseries, motion corrected

% detect artifacts with moving standard deviation
movstd

% segment the motion artifacts into discrete segments, each with start and
% stop

% model with spline interpolation
csaps

% subtract model from artifact segments