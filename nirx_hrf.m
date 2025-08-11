% PURPOSE: function to do simple double-gamma hemodynamic response function
% AUTHOR: Don Rojas, Ph.D.
% HISTORY: 08/09/2025 First version
% TODO: 1. allow changes to defaults, and 2. add dispersions
% CITATION: Friston KJ, Josephs O, Rees G et al. (1998) Non-linear event-related responses in fMRI. 
%           Mag Res Med 39: 41–52
%           Henson, R., & Friston, K. (2007). Convolution models for fMRI. Statistical parametric mapping: 
%           The analysis of functional brain images, 178-192.

function [hrf,t] = nirx_hrf(hdr)

% defaults 
t0 = 0;
t1 = 30; % in seconds, these define window for hrf
p0 = 6;
u0 = 16; % peak and undershoot times, in s
ratio = 1/6; % ratio of undershoot to peak

% sampling interval and times for hrf
Fs = 1/hdr.sr;
t = t0:Fs:t1;

% gamma functions
peak = gampdf(t,p0);
undershoot = gampdf(t,u0);

% combine and scale
tmp = peak - (ratio * undershoot);
hrf = tmp'/sum(tmp);

end
