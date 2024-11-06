function [sd_pairs,sd_dist] = nirx_sd_dist(hdr,pos,labels,selection)
% PURPOSE: function to calculate distances between S-D pairs
% INPUTS:
%   hdr = header from nirx_read_hdr
%   pos = 3d position info from nirx_read_optpos
%   labels = optode labels from nirx_read_optpos
%   selection = 'all' for all possible chans, or 'mask' for those in mask
%   order = 'source', or 'detector', for ordering output

% OUTPUTS:
%   sd_pairs = nchan x 2 array of source detector pairs
%   sd_dist = channel distances, nchan x 1

% Revision history
%   03/01/2022 - fixed bug related to new short channel indexing
%   10/31/2024 - revised to simplify, leaving out distance based selection,
%                which can be handled via scripting or other functions
%   11/06/2024 - changed output to sort in order found in hdr.SDpairs

% defaults
short_dist = 8; % 8 mm fixed short channel distance (NIRx system determined)

% which channels to compute
nsource = hdr.sources;
ndet = hdr.detectors;
switch selection
    case 'all'
        % all potential channels computed
        mask = ones(nsource,ndet);
    case 'mask'
        % only compute on channels in mask
        mask = hdr.SDmask;
    otherwise
        % invalid selection
        error('Selection not valid!');
end

% basic info
ind = find(mask);
[Sfull,Dfull]=ind2sub(size(mask),ind);
sd_pairs_tmp = [Sfull Dfull];

% sources vs. detectors in posfile
sources = find(labels.contains('S'));
detectors = find(labels.contains('D'));
short_detectors = detectors(hdr.shortdetindex); % not currently used in code
long_detectors = setdiff(detectors,short_detectors); % not currently used in code
Spos = pos(sources,:);
Dpos = pos(detectors,:);

% channel distances
for ii = 1:length(Sfull)
    Sloc = Spos(Sfull(ii),:);
    Dloc = Dpos(Dfull(ii),:);      
    tmp_dist(ii) = sqrt(sum((Sloc - Dloc).^2, 2));
end
tmp_dist(find(ismember(hdr.ch_type,'short'))) = short_dist; % 8 mm is hard set in NIRx implementation

% sort output in order of pairings in header S-D pairings
for ii=1:hdr.nchan
    ind = find(sd_pairs_tmp(:,1)==hdr.SDpairs(ii,1) & sd_pairs_tmp(:,2)==hdr.SDpairs(ii,2));
    sd_pairs(ii,:) = sd_pairs_tmp(ind,:);
    sd_dist(ii) = tmp_dist(ind);
end