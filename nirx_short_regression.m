% function to produce optical timeseries corrected for short channels

% input should already be temporally preprocessed (filtered, motion corrected), HbO/HBr data
long=raw(1,:,54); % need to loop
short=raw(1,:,58); % replace with code to find nearest short (separate function call)

% via regression
X=[ones(8615,1) short'];
[b,r2,SEb,tvals,pvals,e]=multregr(X,long');
yscalp = b(2).*short;
corrected = long' - yscalp;

% can also add in global regressor via PCA of short channels, take first
% principal component, see Wyser et al. 2020 neurophotonics, but their take
% is that local is more effective approach.