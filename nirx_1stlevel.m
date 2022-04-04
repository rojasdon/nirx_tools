% PURPOSE: to apply glm, multiple linear regression to nirs data
% INPUTS:
%   X, design structure, see nirx_design_matrix.m, must have:
%   X.X, design matrix
%   X.serial, serial correlation correction method, if desired
%       ('none'|'AR')
%   dat, nsamples x nchannels nirs data (e.g., HbO). Send different
%       hemoglobin estimates through separate analyses.
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
% CITATION: Barker et al.(2013). Autoregressive model based algorithm for correcting motion 
%   and serially correlated errors in fNIRS, Biomedical Optics Express, 4,
%   1366-1379.
% TODO: allow matlab built in ar.m function if installed
% HISTORY: 04/01/2022 - option for contrast input added

function [stat,X] = nirx_1stlevel(X,dat,varargin)
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

    nchan = size(dat,2);
    nsamp = size(dat,1);
    
    % remove mean from channels - no harm if already done
    dat = dat - repmat(mean(dat),nsamp,1);
    
    % channel-wise regression, first pass
    if ~is_contrast
        for chan = 1:nchan
            stat(chan) = multregr(X.X,dat(:,chan));
        end
    else
        for chan = 1:nchan
            stat(chan) = multregr(X.X,dat(:,chan),'contrast',conmat);
        end
    end
    
    % correct for serial correlation, if specified, resulting in
    % Wy = WXβ + Wε 
    if strcmpi(X.serial,'AR')
        
        % ar fit (can use matlab if installed, but default is huppert nirs-toolbox code)
        maxorder = ceil(1/X.dt);
        cf = zeros(nchan,maxorder);
        for chan = 1:nchan
            tmp = nirx_arfit(stat(chan).resid,maxorder); % wrapper to nirs-toolbox code
            tmp(1) = [];
            cf(chan,1:length(tmp)) = tmp;
        end
        
        % construct filters, per channel
        for chan = 1:nchan
           f{chan} = [1; -cf(chan,:)'];
        end
        
        % filter design matrix
        for chan = 1:nchan
           X.Xf{chan} = filter(f{chan},1,X.X);
        end
        
        % filter data matrix
        for chan = 1:nchan
           fdat(:,chan) = filter(f{chan},1,dat(:,chan));
        end
        
        % redo model with filters applied
        if ~is_contrast
            for chan = 1:nchan
                stat(chan) = multregr(X.Xf{chan},fdat(:,chan));
            end
        else
            for chan = 1:nchan
                stat(chan) = multregr(X.Xf{chan},fdat(:,chan),'contrast',conmat);
            end
        end
    end
    
    % end of main
    end
