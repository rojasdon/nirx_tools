% function to compute hemoglobin concentrations from optical density, dpf and extinction data, based in part on posted
% code from Ted Huppert on Homer list:
% https://mail.nmr.mgh.harvard.edu/pipermail//homer-users/2006-July/000124.html
% http://www.ucl.ac.uk/medphys/research/borl/intro/spectra
function [HbO,HbR,HbT] = nirx_mbll(wl,dpf,ec,varargin)

% defaults
L=3; % distance between sources and detectors. This can be vector instead with little effort

% baseline correction and log transform
npoints = length(wl);
od_w1 = -log10(wl(1,:))';
od_w2 = -log10(wl(2,:))';
m_w1 = mean(wl(1,:));
m_w2 = mean(wl(2,:));
od_w1 = od_w1./repmat(m_w1,npoints,1);
od_w2 = od_w2./repmat(m_w2,npoints,1);

% distance * extinction coefficients
distcoef = L.*(diag(dpf)*ec);
distcoef = pinv(distcoef); % inv( e'*e )*e' in Huppert

% Oxy, deoxy and total by least squares
Hb = distcoef * [od_w1'; od_w2'];
HbO = Hb(1,:);
HbR = Hb(2,:);
HbT = HbO+HbR;

