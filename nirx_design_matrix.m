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
% OUTPUTS:
%   X.X, new added field X is design matrix
% HISTORY:
%   04/07/22 - added condition names for plotting
% TODO: allow more than canonical hrf
function X = nirx_design_matrix(X)

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
X.X = vec;

% plot design matrix (for debug only)
visuals = true;
if visuals
    figure('color','w');
    imagesc(vec); axis square;
    ylabel('Samples');
    xlabel('Conditions');
    xticks(1:length(X.names));
    xticklabels(X.names);

end
