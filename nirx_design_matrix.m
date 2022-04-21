% PURPOSE: to create a design matrix suitable for glm/regression
% AUTHOR: Don Rojas, Ph.D.
% INPUTS:
%   X, structure containing:
%   X.basis, 'hrf', only option for now
%   X.dur, duration of events, in seconds (1 x n condition vector)
%   X.dt, sample interval, 1/sampling rate, in seconds
%   X.nsamp, number of samples acquired
%   X.names = n condition x 1 cell array of condition names
%   X.values, trigger codes, see: nirx_read_evt.m
%   X.onsets, onsets in samples, see: nirx_read_evt.m
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
%       columns.
% OUTPUTS:
%   X.X, new added field X is design matrix
% HISTORY:
%   04/07/22 - added condition names for plotting
%   04/15/22 - added optional regressor inputs, X.R
%   04/20/22 - optional input to visualize matrix
% TODO: 1. allow more than canonical hrf e.g., hrf + dispersion
%       2. separate visualization into different function

function X = nirx_design_matrix(X,varargin)

% optional input
if nargin > 1
    visuals = varargin{1};
else
    visuals = true;
end

% conditions and durations
ucond = unique(X.values);
ncond = length(ucond);
ons = cell(1,ncond);
dur = cell(1,ncond);
for ii=1:ncond
    ons{ii} = X.onsets(X.values == ucond(ii));
    durations{ii} = ceil(X.dur(ii)/X.dt);
    fprintf('Trigger=%d, n=%d\n',ucond(ii),length(ons{ii}));
end

% task vectors and convolution with hrf
xBF.dt = X.dt;
xBF.name = X.basis; % 'hrf' for now
xBF = spm_get_bf(xBF);
vec = zeros(ncond,X.nsamp);
for cond = 1:ncond
    vec(cond,ons{cond}) = 1;
    for ii=1:durations{cond} - 1
        spoint = ons{cond} + ii;
        if spoint <= X.nsamp % prevent onsets from extending beyond data
            vec(cond,spoint) = 1;
        end
    end
    tmpvec = conv(vec(cond,:),xBF.bf,'full');
    tmpvec(X.nsamp+1:end) = [];
    vec(cond,:) = tmpvec;
end

% add column of ones for constant, to get intercept from model
vec = [ones(1,X.nsamp); vec]';

% implicit baseline, if requested
switch X.implicit
    case 'yes'
        vec(:,X.baseline + 1) = []; % account for constant column
        X.names(end) = [];
    otherwise
        % do nothing (maybe something later)
end

% add additional regressors if present
if isfield(X,'R')
    vec = [vec X.R];
end
X.X = vec;

% plot design matrix (for debug only)
if visuals
    figure('color','w');
    imagesc(vec); axis square;
    ylabel('Samples');
    xlabel('Conditions');
    xticks(1:length(X.names));
    xticklabels(X.names);
end
