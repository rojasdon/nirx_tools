% example statistical analysis

load('NIRS-2021-09-28_001.mat');
basename = 'NIRS-2021-09-28_001';
hdr = nirx_read_hdr([basename '.hdr']);
outfilesuffix = '_corrected.evt';
[onsets, vals] = nirx_read_evt([basename outfilesuffix]);
dat = nirsdata.oxyData;
X.basis = 'hrf';
X.dur = 10;
X.dt = 1/hdr.sr;
X.nsamp = npoints;
X.values = vals;
X.onsets = onsets;
X.baseline = 9;
X.implicit = 'yes';
X.serial = 'AR';
X.dur = repmat(18,1,9);
X = nirx_design_matrix(X);
[stat, X] = nirx_1stlevel(X,dat);