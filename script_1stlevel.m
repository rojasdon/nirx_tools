% PURPOSE: to script the 1st level of statistical analysis on fnirs data
% (i.e., the individual results)

clear;

%% Preamble/default settings
qa_suffix = 'stats.jpg'; % suffix for quality assurance figures
q_fdr = .05;
screen = get(0,'screensize'); % for setting figure size and location
screen_h = screen(4);
screen_w = screen(3);

% load header and data
filebase = 'NIRS-2021-09-28_001';
load([filebase '_hb_sd.mat']);
hdr = nirx_read_hdr([filebase '.hdr']);
dat = hbo_mcorr_o';
npoints = size(dat,1);

% read events
[onsets, vals] = nirx_read_evt([filebase '_corrected.evt']);
nconditions = length(unique(vals));

% construct design matrix
X = [];
X.basis = 'hrf';
X.dur = repmat(10,1,nconditions);
X.dt = 1/hdr.sr;
X.nsamp = npoints;
X.values = vals;
X.onsets = onsets;
X.baseline = 9;
X.implicit = 'yes';
X.serial = 'AR';
X = nirx_design_matrix(X);

% stats
[stat, X] = nirx_1stlevel(X,dat);
