function q = nirx_snr(data,varargin)
% PURPOSE: Signal to noise (SNR) based metric, as in Yucel et al. (2021)
% best practices paper. 20 * log10(mean/sd)
% AUTHOR: Don Rojas, Ph.D.
% INPUT:
%   data = raw or od intensity data, from nirx_read_wl.m
% OPTIONAL (arg pairs):
%   threshold = threshold for bad channels, default = 20
% OUTPUT:
%   q, a structure containing the following components:
%   q.snr = coefficient of variation for multiple wavelengths
%   q.snrmax = worst cv across wavelengths
%   q.bad = bad channels by threshold using snr
% HISTORY
% NOTE: 20 dB SNR = .1 CV (fraction, not %). 0.075 CV = 22.5 dB SNR
% SEE ALSO: nirx_cv.m

% defaults
threshold = 20; % dB

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
q.snr = 20 * log10(level./dev);
q.cvmax = max(q.snr); % worst wavelength is used for threshold
q.bad = find(q.snr > threshold)';

