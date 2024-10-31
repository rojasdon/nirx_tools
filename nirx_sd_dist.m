function [sd_dist,good,stats] = nirx_sd_dist(hdr,pos,labels,thresholds,type,selection)
% PURPOSE: function to calculate distances between S-D pairs
% INPUTS:
%   basename = file name base w/o ext
%   thresholds = 1 x 2 vector of lower and upper threshold in mm
%   selection = 'all' for all possible chans, or 'mask' for those in mask
%   output = 'yes' to write new corrected hdr and wl files
% OUTPUTS:
%   chdist = channel distances, nchan x 1
%   good = indices of "good" channels by distance, reference to all or mask
%          as per thresholds setting
%   stats = structure containing useful data on gains and distances for
%           extra reporting capability

% FIXME: 1) probably need to sort the S and D indices in case someone inputs S
%   and D out of ascending order in csv file - see
%   script_visualize_chan_dist.m
%   2) change so position file and chfile are inputs, with default
%   3) move s vs. d determination code out of this and other functions

% Revision history
%   03/01/2022 - fixed bug related to new short channel indexing

% defaults
outext = '_dsel';
dothis = 0;
short_dist = 8; % 8 mm fixed short channel distance (NIRx system determined)
type = 'all'; % detector type(s) for channel formation

d_thresh = thresholds; % dist in mm
if length(d_thresh) < 2
    error('You must supply an upper and lower boundary threshold!');
end

% which channels to compute
nsource = hdr.sources;
ndet = hdr.detectors;
if strcmpi(selection,'all')
    % all potential channels computed
    mask = ones(nsource,ndet);
else
    % only compute on channels in mask
    mask = hdr.SDmask;
end

% basic info
ind = find(mask);
[Sfull,Dfull]=ind2sub(size(mask),ind);

% sources vs. detectors in posfile
sources = find(labels.contains('S'));
detectors = find(labels.contains('D'));
short_detectors = detectors(hdr.shortdetindex);
long_detectors = setdiff(detectors,short_detectors);
Spos = pos(sources,:);
switch type
    case 'all'
        Dpos = pos(detectors,:);
    case 'short'
        Dpos = pos(short_detectors,:);
    case 'long'
        Dpos = pos(long_detectors,:);
end

% channel distances - short channel distance is constant
sd_dist = {};
for ii = 1:length(sources)
    tmp = [];
    Sloc = Spos(source_ind,:);
    for jj = 1:length(allnum)
        det_ind = find(ismember(allnum,jj));
        Dloc = Dpos(det_ind,:);
        if find(ismember(sdnum,jj))
            tmp = [tmp short_dist];
        else
            tmp = [tmp sqrt(sum((Sloc - Dloc).^2, 2))];
        end
        fprintf('Source %d - Detector %d: %.2f mm\n',ii,jj,tmp(jj));
    end
    sd_dist{ii} = tmp;
end

% limit to those in mask if requested
    
% mask of distances by threshold
good = find((sd_dist <= d_thresh(2)) & (chdist >= d_thresh(1)));

% reporting by distance
inds = {};
inds{1} = find(chdist <= 10);
inds{2} = find((chdist > 10) & (chdist <= 20));
inds{3} = find((chdist > 20) & (chdist <= 30));
inds{4} = find((chdist > 30) & (chdist <= 40));
inds{5} = find((chdist > 40) & (chdist <= 50));
inds{6} = find((chdist > 50) & (chdist <= 60));
inds{7} = find(chdist > 60);
runsum = 0;
for ii=1:length(inds)-1
    runsum = runsum + length(inds{ii});
    fprintf('%d: n channels %d - %d mm: %d\n',ii, ((ii-1)*10)+1, ((ii-1)*10)+10, length(inds{ii}));
end
runsum = runsum + length(inds{7});
fprintf('7: n channels > 60 mm: %d\n',length(inds{7}));
fprintf('Sum of channels: %d\n',runsum);
fprintf('Good channels by threshold distances: %d\n', length(good));

end