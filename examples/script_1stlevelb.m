% PURPOSE: to script the 1st level of statistical analysis on fnirs data
% (i.e., the individual results)

clear;

%% Preamble/default settings
qa_suffix = 'stats.jpg'; % suffix for quality assurance figures
q_fdr = .05;
screen = get(0,'screensize'); % for setting figure size and location
screen_h = screen(4);
screen_w = screen(3);
%block_dur = 18; % for joystick task
block_dur = 15; % for tapping experiment
con_2_plot = 1; % contrast number for plotting
beta_2_plot = 1; % beta to plot
condition_names = {'Constant','Left','Right','Rest'}; 
%condition_names = {'Constant','ExR_Lat','ImR_Lat','ExL_Vert',...
%     'ImL_Vert','ExR_Vert','ImR_Vert','ExL_Lat','ImL_Lat','Rest'};
% some contrasts for joystick task (columns for intercept + 8 conditions + regressor of no interest).
% Implicit baseline
%conmat = [0 1 0 0 0 1 0 0 0 0 0 0   % all right movements against baseline
%          0 0 0 1 0 0 0 1 0 0 0 0   % all left movements against baseline
%          0 1 0 1 0 1 0 1 0 0 0 0   % all movements against baseline
%          0 -1 0 1 0 -1 0 1 0 0 0 0  % left > right
%          0 1 0 -1 0 1 0 -1 0 0 0 0  % right > left
%          0 1 -1 1 -1 1 -1 1 -1 0 0 0  % Ex > Im
%          0 -1 1 -1 1 -1 1 -1 1 0 0 0]; % Im > Ex

% some contrasts for tapping task (columns for intercept + 3 conditions).
% Implicit baseline contrasts, need zero for any column of confound
% regressor
conmat = [0 1 -1
          0 -1 1];
baseline_condition = 2; % 4 for tapping task, 9 for joystick task

% load header and data
filebase = 'NIRS-2023-03-31_001';
load([filebase '_hb_sd.mat']);
hdr = nirx_read_hdr([filebase '.hdr']);
dat = hbo_HR';
npoints = size(dat,1);

% channel and optode locations
[hline,lbl,pos] = nirx_read_optpos('optode_positions.csv');
chpairs = nirx_read_chconfig('ch_config.txt');
[longpos,shortpos] = nirx_compute_chanlocs(lbl,pos,chpairs,hdr.shortdetindex);

% read events
[onsets, vals] = nirx_read_evt([filebase '.evt']);
nconditions = length(unique(vals));

% construct design matrix
X = [];
Xorig.basis = 'hrf';
Xorig.names = condition_names; % for tapping task
Xorig.dur = repmat(block_dur,1,nconditions);
Xorig.dt = 1/hdr.sr;
Xorig.nsamp = npoints;
Xorig.values = vals;
Xorig.onsets = onsets;
Xorig.baseline = baseline_condition;
Xorig.implicit = 'yes';
Xorig.serial = 'AR-IRLS'; % 'AR'

% PCA for global short channel and global Mayer Wave
hbo_HR_short = hbo_HR_short';
hbo_MW_short = hbo_MW_short';
pc_short = nirx_pca(hbo_HR_short);
pc_MW = nirx_pca(hbo_MW_short);

% stats
for chn = 1:size(longpos,1)
    X = Xorig;
    % Find optimum lag first, lag the regressor, then enter.
    % add nearest short, nearest Mayer wave filtered short, global short, and 
    % global Mayer wave, to design matrix
    % X.R = [squeeze(nearest_hr_sd(chn,:,1))' squeeze(nearest_mw_sd(chn,:,1))' ...
    %    pc_short pc_MW];
    X.R = squeeze(nearest_hr_sd(chn,:,1))'; % only short
    if chn == 1
        X = nirx_design_matrix(X,true);
    else
        X = nirx_design_matrix(X,false);
    end
    % X.X = spm_orth(X.X); % put this into design matrix function!
    [stat(chn), X] = nirx_glm(X,dat(:,hdr.longSDindices(chn)),'contrast',conmat);
end

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

% plotting the main beta results
%tvals = cat(2,stat.tvals);
%pvals = cat(2,stat.pvals);
%tvals = tvals(beta_2_plot,:);
%pvals = pvals(beta_2_plot,:);

% alternative, plotting the contrast results
tmp = arrayfun(@(s) transpose(s.contrast.tvals(con_2_plot)),stat,'uni',false);
tvals = cell2mat(tmp);
tmp = arrayfun(@(s) transpose(s.contrast.pvals(con_2_plot)),stat,'uni',false);
pvals = cell2mat(tmp);

pID = FDR(pvals,q_fdr);
% set face alphas based on pval mask
fa = zeros(1,length(pvals));
ind = find(pvals < pID);
fa(ind) = 1;
nirx_plot_optode3d(longpos,scalp.vertices,N, 'edgecolor',[0 0 1],'facecolor',tvals,...
    'cbar','T statistic','facealpha',fa);