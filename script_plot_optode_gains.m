% script to plot gains or bad gains in NIRx group dataset

% Assumptions:
% 1. that script_optode_corrections.m has been run and _ch_stats.mat
%    file is available to read for each subject
% 2. All files are in same directory
% 3. a 'ch_config.txt' should be in the directory (just one - it is same for
%    all subjects)

% FIXME: write this to use hdr instead of ch_stats

% defaults
badthresh = 7;
plotopt = 0; % set to 0 to plot all gains, 1 for gains thresholded

% read ch_config
chns = nirx_read_chconfig('ch_config.txt');

% Read in the gains
files = dir('*_ch_stats.mat');
nfiles = length(files);
load(files(1).name);
ngains = length(ch_stats.allgains);
gainmat = zeros(nfiles,ngains);
snames = cell(nfiles);
for ii=1:length(files)
    load(files(ii).name);
    tmp = strsplit(files(ii).name,'_');
    [~,tmp,~] = fileparts(tmp{3});
    snames{ii} = tmp;
    gainmat(ii,:) = ch_stats.allgains;
end
mgain = mean(gainmat);

% plot gains
switch plotopt
    case 0
        imagesc(gainmat);
        yticks(1:nfiles);
        h=colorbar;
        ylabel(h,'Gains');
    case 1
        ind = gainmat>badthresh;
        indmat = gainmat;
        indmat(:) = 0;
        indmat(ind) = 1;
        imagesc(indmat);
        yticks(1:nfiles);
end
xlabel('Channels');
ylabel('Subjects');
yticklabels(snames);

% some stats output
nbad = zeros(1,ngains);
ind = [];
for ii=1:ngains
    ind = gainmat(:,ii) > badthresh;
    nbad(ii) = length(find(ind));
end

fp = fopen('gain_stats.txt','w');
fprintf(fp,'Chn\tS\tD\tMean\t#Bad\n');
for ii=1:ngains
    fprintf(fp,'%d\t%d\t%d\t%.1f\t%d\n',chns(ii,1),chns(ii,2),...
        chns(ii,3),mgain(ii),nbad(ii));
end
fclose(fp);
    