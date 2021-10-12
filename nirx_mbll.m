% PURPOSE: function to compute hemoglobin concentrations from optical density, dpf and extinction data
% INPUTS:  1. od, optical density measures, 2 x N timepoint matrix, in form
%                                                               [wl1...N;
%                                                               [wl2...N];
%          2. ec, extinction coefficients, 2x2 matrix of form   [wl1_hbo wl1_hbr;
%                                                                wl2_hbo wl2_hbr]
%          3. dpf, differential pathlength factor, 1x2 in form [wl1 wl2]
%          
% NOTES: Formula conventions from Strangeman et al. (2003. Neuroimage,
%        865-879.
function [HbO,HbR,HbT] = nirx_mbll(od,dpf,ec,varargin)
% defaults
if nargin > 3
    L = varargin{1};
else
    L = 3; % distance between source and detector.
end
    
% baseline correction and log transform
npoints = length(od);
m_w1 = mean(od(1,:));
m_w2 = mean(od(2,:));
dOD1 = od(1,:) ./ repmat(m_w1,1,npoints); % baseline corrected od
dOD2 = od(2,:) ./ repmat(m_w2,1,npoints);
clear od;

% change in tissue absorption dMu in MBLL
dMu1 = dOD1 * L * dpf(1);
dMu2 = dOD2 * L * dpf(2);

% HbO, HbR, HbT (Formula 2, Strangeman)
HbR = ((ec(2,1) * dMu1) - (ec(1,1) * dMu2)) ./ (((ec(1,2) * ec(2,1))) - (ec(1,1) * ec(2,2)));
HbO = ((ec(1,2) * dMu2) - (ec(2,2) * dMu1)) ./ (((ec(1,2) * ec(2,1))) - (ec(1,1) * ec(2,2)));
HbT = HbR + HbO;


