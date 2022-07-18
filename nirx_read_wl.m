function [raw,cols,S,D] = nirx_read_wl(basename,hdr,varargin)
% function to read wl1 and wl2 files from nirx
% Inputs:
%   1. basename = file base name without extension
%   2. hdr = structure returned from hdr_read_hdr.m
% Optional Input:
%   1. Chanopt = 'mask' (default) or 'all' to return only masked channels
%      or all possible S-D pairings
% Outputs:
%   1. raw = raw data for wavelengths
%   2. cols = column indices where data were found from full array
%   3. S = Sources
%   4. D = Detectors [S D] gives pairs that form channels

% file extensions to read
ext = {'.wl1','.wl2'};

% return full data or masked data from hdr
if nargin > 2 && strcmpi(varargin{1},'all')
    fullraw = 1;
else
    fullraw = 0;
end

% channels to read
nchan       = hdr.nchan;
nSource     = hdr.sources;
nDetector   = hdr.detectors;

% note that .wl1 and .wl2 files contain all possible channels regardless of masking
% in acquisition view. So if 16 sources and 16 detectors, then should have
% 256 channels (sec 13.2 NIRStar manual 14-0)

% to get S/D indices
M       = hdr.SDmask;
ind     = find(M);
[S,D]   = ind2sub(size(M),ind); % S and D are indices for non-masked chans
[S sind] = sort(S);
D       = D(sind);

% transform S and D indices into columns of interest in wl files, using
% formula in NIRStar 14-0 manual, section 13.2
% CHECK THIS: chans 1 and 49 look fine compared with nirslab, but look at
% 2...48, can prob check on S-D-Key as well
for ii = 1:nchan
    cols(ii) = (S(ii)-1) * nDetector + D(ii);
end
%cols = sort(cols);

% open data file and read contents
for ii = 1:length(ext)
    raw(ii,:,:) = importdata([basename ext{ii}],' ');
end

% limit to non-masked channels?
if ~fullraw
    raw = raw(:,:,cols);
end

end