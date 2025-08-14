% PURPOSE: to create a design matrix suitable for glm/regression
% AUTHOR: Don Rojas, Ph.D.
% INPUTS:
%   X, structure containing:
%   X.basis, 'hrf', only option for now
%   X.dur, duration of events, in seconds (1 x n condition vector)
%   X.sr, sampling rate
%   X.nsamp, number of samples acquired
%   X.names = n condition x 1 cell array of condition names
%   X.values, trigger codes, see: nirx_read_evt.m
%   X.onsets, onsets in samples, see: nirx_read_evt.m (n_onsets x
%             n_conditions)
%   X.baseline, scalar indicating which condition is baseline, if coded.
%       can leave this empty if no trigger was used for baseline/rest
%   X.implicit, 'yes'|'no', implicit baselines ('yes') do not model the
%       rest, avoiding overfitting. To include an explicit baseline
%       condition, this should be 'no'.
%   X.R, optional additional regressors. Can be either 1 x X.nsamp column
%       vector of single regressor, or n x X.nsamp array of regressor columns.
%       This is intended to add confounds such as local or global short channel/scalp
%       estimates, or motion, but could also be used for added variables of
%       interest. If added, X.names should be combined length of all
%       columns. Scale these from 0-1
% OUTPUTS:
%   .X, new added field X is design matrix
%   .Xstick, X without convolution
% HISTORY:
%   04/07/22 - added condition names for plotting
%   04/15/22 - added optional regressor inputs, X.R
%   04/20/22 - optional input to visualize matrix
%   08/12/25 - rework for clarity and consistency
% TODO: 1. allow more than canonical hrf e.g., hrf + dispersion
%       2. separate visualization into different function

function X = nirx_design_matrix(X,varargin)

% optional input
if nargin > 1
    visuals = varargin{1};
else
    visuals = true;
end

% sampling interval
X.dt = 1/X.sr;

% conditions and durations
ucond = unique(X.values);
ncond = length(ucond);
ons = cell(1,ncond);
dur = cell(1,ncond);
X.dur = ceil(X.dur/X.dt); % convert seconds to samples
for ii=1:ncond
    ons{ii} = X.onsets(X.values == ucond(ii));
    durs{ii} = X.dur(X.values == ucond(ii));
    fprintf('Condition=%d, n=%d\n',ucond(ii),length(ons{ii}));
end

% tested

% task vectors and convolution with hrf
bf = nirx_hrf(X.sr); % canonical hrf basis function only for now
vec = zeros(X.nsamp,ncond);
vechrf = vec;

for cond = 1:ncond
    vec(ons{cond},cond) = 1;
    for ii=1:durs{cond} - 1 
        spoint = ons{cond} + ii;
        if spoint <= X.nsamp % prevent onsets from extending beyond data
            vec(spoint,cond) = 1;
        end
    end
    tmpvec = conv(vec(:,cond),bf,'full');
    tmpvec(X.nsamp+1:end,:) = [];
    vechrf(:,cond) = tmpvec;
end

% add column of ones for constant, to get intercept from model
vechrf = [ones(X.nsamp,1) vechrf];

% implicit baseline, if requested
switch X.implicit
    case 'yes'
        vechrf(:,X.baseline + 1) = []; % +1 to account for constant column
        X.names(end) = [];
    otherwise
        % do nothing (maybe something later)
end

% add additional regressors if present (not convolved with basis function)
if isfield(X,'R')
    X.R = detrend(X.R);
    vechrf = [vechrf X.R];
end
X.X = vechrf;
X.Xstick = vec; % non-convolved version

% plot design matrix (for debug only)
if visuals
    figure('color','w');
    imagesc(X.X); axis square;
    ylabel('Samples');
    xlabel('Regressors');
    xticks(1:length(X.names)+1);
    xticklabels(['constant';X.names]);
    colormap gray;
end
