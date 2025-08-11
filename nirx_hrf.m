% PURPOSE:  Function to do simple double-gamma hemodynamic response function
% AUTHOR:   Don Rojas, Ph.D.
% HISTORY:  08/09/2025 First version
% INPUT:    Sampling rate, such as from hdr = nirx_read_hdr(...)
% CITATION: Friston KJ, Josephs O, Rees G et al. (1998) Non-linear event-related responses in fMRI. 
%           Mag Res Med 39: 41–52
%           Henson, R., & Friston, K. (2007). Convolution models for fMRI. Statistical parametric mapping: 
%           The analysis of functional brain images, 178-192.

function [hrf,t] = nirx_hrf(sr,varargin)

% defaults (peak and undershoot times from SPM12 defaults)
t0 = 0;
t1 = 30; % in seconds, these define window for hrf
p0 = 6;
u0 = 16; % peak and undershoot times, in s
ratio = 1/6; % ratio of undershoot to peak
scale = 1;

% parse variable inputs
if ~isempty(varargin)
        optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for opt=1:2:optargin
            switch varargin{opt}
                case 'peaks'
                    tmp = varargin{opt+1};
                    p0 = tmp(1);
                    u0 = tmp(2);
                otherwise
                    error('Invalid option!');
            end
        end
    end
end

% sampling interval and times for hrf
Fs = 1/sr;
t = t0:Fs:t1;

% gamma functions
peak = gampdf_custom(t,p0,scale); % alt: gampdf(t,p0,scale), but that uses statistics toolbox
undershoot = gampdf_custom(t,u0,scale);

% combine and scale
tmp = peak - (ratio * undershoot);
hrf = tmp'/sum(tmp); % normalize and return

end
