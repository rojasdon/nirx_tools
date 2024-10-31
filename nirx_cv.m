function q = nirx_cv(data,varargin)
% PURPOSE: NIRx signal quality metric, same as calculated at calibration,
%          but on specified data input to function
% AUTHOR: Don Rojas, Ph.D.
% INPUT:
%   data = raw or od intensity data, from nirx_read_wl.m
% OPTIONAL (arg pairs):
%   threshold = threshold for bad channels
% OUTPUT:
%   q, a structure containing the following components:
%   q.cv = coefficient of variation for multiple wavelengths
%   q.cvmax = worst cv across wavelengths
%   q.bad = bad channels by threshold using cvmax
% HISTORY

% defaults
threshold = 7.5;

% check/process input arguments
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for i=1:2:optargin
            switch varargin{i}
                case 'threshold'
                    threshold = varargin{i+1};
                otherwise
                    error('Invalid option!');
            end
        end
    end
end

% calculate level and noise measures
level = squeeze(mean(data,2));
dev = squeeze(std(data,[],2));
q.cv = (dev./level)*100;
q.cvmax = max(q.cv); % worst wavelength is used for threshold
q.bad = find(q.cvmax > threshold)';

