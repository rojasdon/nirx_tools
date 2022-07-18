function [sd_dist,good,stats] = nirx_sd_dist(basename,thresholds,selection,output)
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
posfile = 'optode_positions.csv';
chfile = 'ch_config.txt';
outext = '_dsel';
dothis = 0;
short_dist = 8; % 8 mm fixed short channel distance (NIRx system determined)

d_thresh = thresholds; % dist in mm
if length(d_thresh) < 2
    error('You must supply an upper and lower boundary threshold!');
end

% read files
if ~exist(posfile,'file')
    error('You must have a position file called %s\n',posfile);
end
[~,lbl,pos]=nirx_read_chpos(posfile);
hdr=nirx_read_hdr([basename '.hdr']);

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

% sources vs. detectors in posfile, accounting for numbering being out of
% order in csv file
sind = [];
snum = [];
ldind = [];
ldnum = [];
sdind = [];
sdnum = [];
for ii=1:length(lbl)
    if lbl{ii}{1}(1)=='S'
        sind = [sind ii];
        snum = [snum str2double(lbl{ii}{1}(2:end))];
    elseif lbl{ii}{1}(1)=='D'
        if ~isempty(find(ismember(hdr.shortdetindex,...
                str2double(lbl{ii}{1}(2:end)))))
            sdind = [sdind ii];
            sdnum = [sdnum str2double(lbl{ii}{1}(2:end))];
        else
            ldind = [ldind ii];
            ldnum = [ldnum str2double(lbl{ii}{1}(2:end))];
        end
    end
end
Spos = pos(sind,:);
allind = [ldind sdind]; % shorts will be last
allnum = [ldnum sdnum];
Dpos = pos(allind,:);

% channel distances - short channel distance is constant
sd_dist = {};
for ii = 1:length(snum)
    tmp = [];
    source_ind = find(ismember(snum,ii));
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
good = [];
stats = []; % remove stats from call - move to qa function

%%% need to go through nirx_read_optpos.m, nirx_compute_chanlocs.m,
%%% nirx_nearest_short.m and nirx_nearest_neighbors.m and check
%%% computations.
% also remove the nirx_chan_dist.m and nirx_read_chpos.m functions from
% circulation because the sd_dist and optpos functions replace them with
% better names

if dothis

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

% report gain info on potentially good chans
newgains = hdr.gains(good);
fprintf('# S-D pairs within distance threshold with gain <=7: %d\n', length(find(newgains<=7)));
fprintf('For those channels, mean +/- SD gain are: %.2f +/- %.2f\n', mean(newgains(newgains<=7)),std(double(newgains(newgains<=7))));
fprintf('For all %d channels in mask, mean +/- SD gain: %.2f +/- %.2f\n', length(good), mean(newgains(:)),std(double(newgains(:))));

% construct stats for convenient data collection
allgains = hdr.gains;
gains = zeros(length(ind),1);
for ii = 1:length(Sfull)
    gains(ii) = allgains(Sfull(ii),Dfull(ii));
end
for ii=1:7
    mgain(ii) = mean(gains(inds{ii}));
    sdgains(ii) = std(gains(inds{ii}));
end
stats.gainbins = {'<10';'11-20';'21-30';'31-40';'41-50';'51-60';'>60'};
stats.mgain = mgain;
stats.sdgains = sdgains;
stats.sd = [Sfull Dfull];
stats.allgains = gains;
stats.dist = roundp(chdist/10,1); % save in cm for spm_fnirs

% output new data if requested
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
    nirx_write_hdr([basename outext '.hdr'],newhdr);
    % copy wl* files to new names for convenience
    copyfile([basename '.wl1'],[basename outext '.wl1']);
    copyfile([basename '.wl2'],[basename outext '.wl2']);
end
end