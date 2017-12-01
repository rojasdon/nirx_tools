function [U,W,compsig,cum_var] = nirx_ica(data,varargin)
% function to return ICA components from NIRX input data

% 'pca'      n components to retain from pca (default =
%                               25)
% add in linregr function option and regressor input to return r vals
% add in 2d topographic stuff

% requires fastica installation
if isempty(exist('fastica','file'))
    error('FastICA must be installed and on the Matlab path!');
end

% defaults
usetrials = 1;
ncomp = 25;
topoplot = 0;
method = 'ica';

% check arguments
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for ii=1:2:optargin
            switch upper(varargin{ii})
                case 'LASTEIG'
                    ncomp = varargin{ii+1};
                case 'METHOD'
                    method = varargin{ii+1};
                otherwise
                    error('Invalid option!');
            end
        end
    end
else
    error('Arguments are required for this function!');
end

% check data
if ~ismatrix(data)
    error('Data should have only 2 dimensions: nchans x npoints!');
end
npoints = size(data,2);
nchan = size(data,1);

% perform ICA/PCA
rowmeans = mean(data,2);
if strcmpi(method,'ica')
    [compsig, U, W] = fastica(data, 'lastEig', ncomp,'stabilization','on');
else
    [U, W] = fastica(data, 'lastEig', ncomp,'only','pca');
    compsig = pinv(U) * eye(nchan) * (data-repmat(rowmeans,1,npoints));
end
perc_var = diag(W)/sum(diag(W))*100;
cum_var = cumsum(perc_var);
    
% if plot requested
if topoplot == 1
    nsig = size(ic_timecourses,1);
    figure('color','w');
    for line = 1:nsig
        plot(time,ic_timecourses(line,:)+(line*5));
        hold on;
    end
end

end