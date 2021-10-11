% function to produce optical timeseries corrected for short channels,
% methods described in:

% Wyser, D., Mattille, M., Wolf, M., Lambercy, O., Scholkmann, F., & Gassert, R. (2020). Short-channel regression in functional near-infrared spectroscopy 
% is more effective when considering heterogeneous scalp hemodynamics. Neurophotonics, 7(3), 035011. http://doi.org/10.1117/1.NPh.7.3.035011

% inputs should likely be header, data, nearest ss channel list (look at megtools
% examples) and options for global PCA, local, both
hdr = nirx_read_hdr('NIRS-2021-09-28_001.hdr');
[raw, cols, S,D]=nirx_read_wl('NIRS-2021-09-28_001',hdr);

% outputs should be corrected data channels, maybe selected regression results?

% input should already be temporally preprocessed (filtered, motion corrected), HbO/HBr data
long=raw(1,:,54); % need to loop
short=raw(1,:,58); % replace with code to find nearest short (separate function call)

% regression on single short channel
X=[ones(8615,1) short']; % regressors, just constant and short chan here
[b,r2,SEb,tvals,pvals,e]=multregr(X,long'); % regression, long chan = Y
yscalp = b(2).*short; % scalp signal b(1) is intercept
corrected = long' - yscalp'; % corrected signal

% can also add in global regressor via PCA of short channels, take first
% principal component, see Wyser et al. 2020 neurophotonics, but their take
% is that local is more effective approach. Might not be true in our case
% given that local signal is less local for some chans than others
shorts = squeeze(raw(1,:,hdr.shortdetindex));
[coeff,comp]=pca(shorts);
X=[ones(8615,1) comp(:,1)];
[b,r2,SEb,tvals,pvals,e]=multregr(X,long');
yscalp = b(2).*comp(:,1); % scalp signal b(1) is intercept
corrected = long' - yscalp; % corrected signal