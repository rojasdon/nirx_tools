% PURPOSE: to return n principal components from input timeseries
% AUTHOR: Don Rojas, Ph.D.
% INPUTS: data, N channels x P samples
%         ncomp, optional N top components to return from PCA (default = 1)
% OUTPUTS: pc, principal components in descending order of explained
%              variance
%          var, explained variance for each component returned
% HISTORY: 04/21/22 - first working version
%       

function [pc, var] = nirx_pca(data,varargin)

% defaults
if nargin > 1
    ncomp = varargin{1};
else
    ncomp = 1;
end

% mean center
mu = mean(data);
Xm = bsxfun(@minus, data ,mu);

% SVD/PCA
[coeff,v] = svd(cov(Xm));

% sorting
[v, ind] = sort(diag(v), 'descend');% sort values in descending order
var = 100 * v/sum(v); % variances of principal components
coeff = coeff(:,ind); % principal component coefficients
pc = Xm * coeff'; % each column is component 

% output
pc = pc(:,1:ncomp);
var = var(1:ncomp);