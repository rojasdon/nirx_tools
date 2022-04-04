% PURPOSE: to script the 1st level of statistical analysis on fnirs data
% (i.e., the individual results)

clear;

%% Preamble/default settings
qa_suffix = 'stats.jpg'; % suffix for quality assurance figures
q_fdr = .1;
screen = get(0,'screensize'); % for setting figure size and location
screen_h = screen(4);
screen_w = screen(3);
block_dur = 18;
con_2_plot = 6; % regressor number for plotting
conmat = [0 1 0 0 0 1 0 0 0    % all right movements against baseline
          0 0 0 1 0 0 0 1 0    % all left movements against baseline
          0 1 0 1 0 1 0 1 0    % all movements against baseline
          0 -1 0 1 0 -1 0 1 0  % left > right
          0 1 0 -1 0 1 0 -1 0  % right > left
          0 1 -1 1 -1 1 -1 1 -1 % Ex > Im
          0 -1 1 -1 1 -1 1 -1 1]; % Im > Ex


% load header and data
filebase = 'NIRS-2021-09-28_001';
load([filebase '_hb_sd.mat']);
hdr = nirx_read_hdr([filebase '.hdr']);
dat = hbt_mcorr_o';
npoints = size(dat,1);

% channel and optode locations
[hline,lbl,pos] = nirx_read_optpos('optode_positions.csv');
chpairs = nirx_read_chconfig('ch_config.txt');
[longpos,shortpos] = nirx_compute_chanlocs(lbl,pos,chpairs,hdr.shortdetindex);

% read events
[onsets, vals] = nirx_read_evt([filebase '_corrected.evt']);
nconditions = length(unique(vals));

% construct design matrix
X = [];
X.basis = 'hrf';
X.dur = repmat(block_dur,1,nconditions);
X.dt = 1/hdr.sr;
X.nsamp = npoints;
X.values = vals;
X.onsets = onsets;
X.baseline = 9;
X.implicit = 'yes';
X.serial = 'AR';
X = nirx_design_matrix(X);

% stats
[stat, X] = nirx_1stlevel(X,dat,'contrast',conmat);

% plotting basic brain setup
spm_dir = fullfile(spm('dir'),'canonical');
scalp = gifti(fullfile(spm_dir, 'scalp_2562.surf.gii'));
cortex = gifti(fullfile(spm_dir,'cortex_20484.surf.gii'));
braincolor = [200 120 105]./255;
figure('color','white');
s = patch('vertices',scalp.vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
S = s.Vertices;
N = patchnormals(scalp);
alpha(s,.3);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
camlight left; camlight right;
lighting gouraud;
rotate3d on;

% contrast plotting
%tvals = cat(2,stat.tvals);
%pvals = cat(2,stat.pvals);
%tvals = tvals(beta_to_plot,hdr.longSDindices);
%pvals = pvals(beta_to_plot,hdr.longSDindices);
tmp = arrayfun(@(s) transpose(s.contrast.tvals(con_2_plot)),stat(hdr.longSDindices),'uni',false);
tvals = cell2mat(tmp);
tmp = arrayfun(@(s) transpose(s.contrast.pvals(con_2_plot)),stat(hdr.longSDindices),'uni',false);
pvals = cell2mat(tmp);
pID = FDR(pvals,q_fdr);
% set face alphas based on pval mask
fa = zeros(1,length(pvals));
ind = find(pvals < pID);
fa(ind) = 1;
nirx_plot_optode3d(longpos,scalp.vertices,N, 'edgecolor',[0 0 1],'facecolor',tvals,...
    'cbar','T statistic','facealpha',fa);