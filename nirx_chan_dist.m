function [chdist,good] = nirx_chan_dist(hdr,pos,lbl,thresholds,selection,type)
% function to calculate distances between S-D pairs
% inputs:
%   hdr = header from nirx_read_hdr.m
%   pos = Nchan x 3 positions from nirx_read_optpos.m
%   lbl = optode labels from nirx_read_optpos.m
%   thresholds = 1 x 2 vector of lower and upper threshold in mm
%   selection = 'all' for all possible chans, or 'mask' for those in mask
%   type = 'all','long', or 'short' channels
% outputs:
%   chdist = channel distances, nchan x 1
%   good = indices of "good" channels by distance, reference to all or mask
%          as per thresholds setting

% FIXME: 1) probably need to sort the S and D indices in case someone inputs S
% and D out of ascending order in csv file - see
% script_visualize_chan_dist.m
% 2) should rename function to nirx_optode_dist or nirx_sd_dist because
% the optodes are not the channel locations. Separate function,
% nirx_compute_chanlocs.m for channel locations from s-d pairings
% Revision history
% 03/01/2022 - fixed bug related to new short channel indexing
% 08/10/2024 - flexibility to return different channel types, removed gain
%              reporting and stats, these are done by other functions now

% checks/defaults
d_thresh = thresholds; % dist in mm
if length(d_thresh) < 2
    error('You must supply an upper and lower boundary threshold!');
end
output = "no"; % remove this see TODO later

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
full_nchan = length(hdr.SDkey);

% sources vs. detectors in posfile
sind = [];
ldind = [];
sdind = [];
for ii=1:length(lbl)
    if lbl{ii}(1)=='S'
        sind = [sind ii];
    elseif lbl{ii}(1)=='D'
        if ~isempty(find(ismember(hdr.shortdetindex,...
                str2double(lbl{ii}(2:end)))))
            sdind = [sdind ii];
        else
            ldind = [ldind ii];
        end
    end
end
Spos = pos(sind,:);
switch type
    case 'all'
        Dpos = [pos(ldind,:); pos(sdind,:)];
    case 'short'
        Dpos = pos(sdind,:);
    case 'long'
        Dpos = pos(ldind,:);
end

% channel distances
for ii = 1:length(Sfull)
    fprintf('%d\n',ii);
    Sloc = Spos(Sfull(ii),:);
    Dloc = Dpos(Dfull(ii),:);      
    chdist(ii,:) = sqrt(sum((Sloc - Dloc).^2, 2));
end
chdist(find(ismember(hdr.ch_type,'short'))) = 8; % 8 mm is hard set in NIRx implementation

% mask of distances by threshold
good = find((chdist <= d_thresh(2)) & (chdist >= d_thresh(1)));

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

% output new data if requested TODO - move to separate function
if strcmpi(output,'yes')
    % new header mask, s-d-key, etc
    newhdr = hdr;
    newmask = zeros(size(mask));
    maskind = sub2ind(size(mask),Sfull(good),Dfull(good));
    newmask(maskind) = 1;
    newhdr.SDmask = newmask;
    newSDpairs = [Sfull(good) Dfull(good)];
    [y,ipair] = sort(newSDpairs(:,1));
    newhdr.SDpairs = [y newSDpairs(ipair,2)];
    newhdr.dist = roundp(chdist(good),1);
    newhdr.nchan = length(good);
    newhdr.chnums = 1:newhdr.nchan;
    % write a new ch_config file
    [~,nam,ext] = fileparts(chfile);
    movefile(chfile,[nam '_cdist_orig' ext]);
    nirx_write_ch_config(chfile,newhdr);
    % write a corrected header file
    nirx_write_hdr([hdr outext '.hdr'],newhdr);
    % copy wl* files to new names for convenience
    copyfile([hdr '.wl1'],[hdr outext '.wl1']);
    copyfile([hdr '.wl2'],[hdr outext '.wl2']);
end