% PURPOSE: to apply glm, multiple linear regression to nirs data
% INPUTS:
%   X,          design structure, see nirx_design_matrix.m, must have:
%   X.X,        design matrix, which includes columns of regressors of interest
%               (e.g., conditions in an experiment), columns of regressors of confounds
%               (e.g., a column of short channel data), etc.
%   X.serial,   serial correlation correction method, if desired
%               ('none'|'AR(1)'|...'). Options include:
%               'none', no correction
%               'AR(1)', AR with order specified (AR(2), AR(3), etc.)
%               'AR', AR model with optimum order per channel estimate
%               'AR-IRLS', AR iteratively reweighted least squares
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
%       .resid
%   X, structure containing Xf, AR filtered design matrix
% CITATION: If using AR-IRLS approach, Barker et al.(2013). Autoregressive model based algorithm for correcting motion 
%   and serially correlated errors in fNIRS, Biomedical Optics Express, 4,
%   1366-1379.
% TODO: allow matlab built in ar.m function if installed
% HISTORY: 04/01/2022 - option for contrast input added
%          04/15/2022 - rewrote to take only one channel to facilitate
%                       short-channel use in GLM
%          07/13/2022 - changed name to nirx_glm.m, added AR options
%                       including AR-IRLS

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
    % Wy = WXβ + Wε, where weights are applied using filter to both sides
    % of equation
    if contains(X.serial,'AR')
        maxorder = ceil(1/X.dt);
        % determine type of AR model requested
        if contains(X.serial,'AR(')
            pindex = find(ismember(X.serial,')'));
            order = str2num(X.serial(4:pindex-1));
            coeff = ar_model(stat.resid,order);
            X.coeff = coeff;
        else
            [coeff,~]=ar_model(stat.resid,1,'maxorder',maxorder); % AR final or AR-IRLS first pass
            X.coeff = coeff;
        end  

        % AR-IRLS or other AR models
        if contains(X.serial,'AR-IRLS')
            crit = 2; % percent change in beta
            while crit(1) > 1
                B = stat.beta;
                r = stat.resid;
                stat = weightedLS(X,dat,r,maxorder);
                crit = (stat.beta - B)/B * 100;
            end
        else
            stat = weightedLS(X,dat,stat.resid,maxorder);
        end

    end
    
% end of main
end

function stat = weightedLS(X,dat,r,maxorder)
% local function to apply filters to regression
    
    if isfield(X,'coeff')
        coeff = X.coeff;
    else
        % ar_model from residuals
        [coeff,~]=ar_model(r,1,'maxorder',maxorder);
    end
    
    % construct filter from coefficient weights
    f = [coeff(1); -coeff(2:end)];
    
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
