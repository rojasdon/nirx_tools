% PURPOSE: to apply glm, multiple linear regression to nirs data
% INPUTS:
%   X, design structure, see nirx_design_matrix.m, must have:
%   X.X, design matrix
%   X.serial, serial correlation correction method, if desired
%       ('none'|'AR')
%   dat, nsamples x nchannels nirs data (e.g., HbO). Send different
%       hemoglobin estimates through separate analyses.
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
function [stat,X] = nirx_1stlevel(X,dat)

    nchan = size(dat,2);
    nsamp = size(dat,1);
    
    % remove mean from channels - no harm if already done
    dat = dat - repmat(mean(dat),nsamp,1);
    
    % channel-wise regression, first pass
    for chan = 1:nchan
        [stat(chan).b,stat(chan).r2,stat(chan).SEb,stat(chan).tvals,...
            stat(chan).pvals,stat(chan).e] = multregr(X.X,dat(:,chan));
    end
    
    % correct for serial correlation, if specified, resulting in
    % Wy = WXβ + Wε 
    if strcmpi(X.serial,'AR')
        
        % ar fit (can use matlab if installed, but default is huppert code)
        maxorder = ceil(1/X.dt);
        cf = zeros(nchan,maxorder);
        for chan = 1:nchan
            tmp = nirx_arfit(stat(chan).e,maxorder);
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
        for chan = 1:nchan
            [stat(chan).b,stat(chan).r2,stat(chan).SEb,stat(chan).tvals,...
                stat(chan).pvals,stat(chan).e] = multregr(X.Xf{chan},fdat(:,chan));
        end
    end
    
    % end of main
    end
