% Purpose: To correct motion related noise in fnirs data by PCA
% Author: Don Rojas, Ph.D.
% Citation: 
function cdata = nirx_motion_pca(data,hdr)

hdr=nirx_read_hdr('029-2015-12-05_001.hdr');
[raw, ~, ~,~]=nirx_read_wl('029-2015-12-05_001',hdr);

nchan=hdr.nchan;

nSV = .97; % Cooper et al. 2012

d=squeeze(raw(1,:,:));

dN=d;

% PCA by SVD
y = d;
sig = y.'* y;
[U,S,V] = svd(sig);

pve = diag(S)./ sum(diag(S));
cpve = cumsum(pve);
[~,ind] = min(abs(cpve - nSV));
ev=zeros(size(pve,1),1);
ev(1:ind)=1;
ev=diag(ev);



% reconstruct without some SVs
% newdata = U(ind:end,:)*S*V';
yc=y-(y*V*ev*V');
