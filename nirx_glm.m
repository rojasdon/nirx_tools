% PURPOSE: to apply glm, multiple linear regression to nirs data
% INPUTS:
%   X, design structure, see nirx_design_matrix.m, must have:
%   X.X, design matrix, which includes columns of regressors of interest
%   (e.g., conditions in an experiment), columns of regressors of confounds
%   (e.g., a column of short channel data), etc.
%   X.serial, serial correlation correction method, if desired
%       ('none'|'AR')
%   dat, nsamples x 1 channel nirs data (e.g., HbO, HbR, etc.).
% OPTIONAL, in option/value pairs:
%   'contrast', conmat, where conmat is n contrast by n + 1 condition
%               vector, where n + 1 = size(X,2)
% OUTPUTS:
%   stat, output (nchan) structure containing (see multregr.m for details)
%       .beta
%       .r2
%       .SEb
%       .pvals
%       .e 
%   X, structure containing Xf, AR filtered design matrix
% CITATION: If using AR-IRL approach, Barker et al.(2013). Autoregressive model based algorithm for correcting motion 
%   and serially correlated errors in fNIRS, Biomedical Optics Express, 4,
%   1366-1379.
% TODO: allow matlab built in ar.m function if installed
% HISTORY: 04/01/2022 - option for contrast input added
%          04/15/2022 - rewrote to take only one channel to facilitate
%                       short-channel use in GLM
%          07/13/2022 - changed name to nirx_glm.m, added robust regression
%                       option and IRL part of AR-IRL

function [stat,X] = nirx_glm(X,dat,varargin)
    % default
    is_contrast = false;

    % check input arguments
    if ~isempty(varargin)
        optargin = size(varargin,2);
        if (mod(optargin,2) ~= 0)
            error('Optional arguments must come in option/value pairs');
        else
            for i=1:2:optargin
                switch varargin{i}
                    case 'contrast'
                        conmat = varargin{i+1};
                        is_contrast = true;
                    otherwise
                        error('Invalid option!');
                end
            end
        end
    end
    
    % remove mean from channels - no harm if already done
    dat = dat - mean(dat);
    
    % channel-wise regression, first pass
    if ~is_contrast
        stat = multregr(X.X,dat);
    else
        stat = multregr(X.X,dat,'contrast',conmat);
    end
    
    % correct for serial correlation, if specified, resulting in
    % Wy = WXβ + Wε 
    if strcmpi(X.serial,'AR-IRL')
        
        % ar fit using matlab (econometrics toolbox must be installed)
        maxorder = ceil(1/X.dt);
        cf = zeros(maxorder,1);
        tmp = nirx_arfit(stat.resid,maxorder); % wrapper to nirs-toolbox code
        tmp(1) = [];
        cf(1:length(tmp)) = tmp;
        
        % construct filter
        f = [1; -cf];
        
        % filter design matrix
        X.Xf = filter(f,1,X.X);
        
        % filter data matrix
        fdat = filter(f,1,dat);
        
        % redo model with filters applied
        if ~is_contrast
            stat = multregr(X.Xf,fdat);
        else
            stat = multregr(X.Xf,fdat,'contrast',conmat);
        end
    end
    
    % end of main
    end
