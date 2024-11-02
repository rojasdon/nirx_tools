function [sd_pairs,sd_dist] = nirx_sd_dist(hdr,pos,labels,selection)
% PURPOSE: function to calculate distances between S-D pairs
% INPUTS:
%   basename = file name base w/o ext
%   selection = 'all' for all possible chans, or 'mask' for those in mask

% OUTPUTS:
%   sd_pairs = nchan x 2 array of source detector pairs
%   sd_dist = channel distances, nchan x 1

% Revision history
%   03/01/2022 - fixed bug related to new short channel indexing
%   10/31/2024 - revised to simplify, leaving out distance based selection,
%                which can be handled via scripting or other functions

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
sd_pairs = [Sfull Dfull];

% sources vs. detectors in posfile
sources = find(labels.contains('S'));
detectors = find(labels.contains('D'));
short_detectors = detectors(hdr.shortdetindex);
long_detectors = setdiff(detectors,short_detectors);
Spos = pos(sources,:);
Dpos = pos(detectors,:);

% channel distances
for ii = 1:length(Sfull)
    fprintf('%d\n',ii);
    Sloc = Spos(Sfull(ii),:);
    Dloc = Dpos(Dfull(ii),:);      
    sd_dist(ii,:) = sqrt(sum((Sloc - Dloc).^2, 2));
end
sd_dist(find(ismember(hdr.ch_type,'short'))) = short_dist; % 8 mm is hard set in NIRx implementation

end