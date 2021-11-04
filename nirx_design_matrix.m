% create/visualize experimental design
clear;

duration = 16; % seconds

basename = 'NIRS-2021-09-28_001';
[onsets, vals]=nirx_read_evt([basename '_corrected.evt']);
hdr = nirx_read_hdr([basename '.hdr']);
[raw,~,~,~] = nirx_read_wl(basename,hdr);
npoints = size(raw,2);
load([basename '.mat']);

% duration to samples from seconds
duration = round(duration./(1/hdr.sr));

% conditions
ucond = unique(vals);
ncond = length(ucond);
for ii=1:ncond
    ons{ii} = onsets(vals == ucond(ii));
    fprintf('Trigger=%d, n=%d\n',ucond(ii),length(ons{ii}));
end

% task vectors and convolution with hrf
% NOTE: delays, etc. modeling?
%[hrf, p] = spm_hrf(hdr.sr); % check with spm_fnirs code
xBF.dt = 1/hdr.sr;
xBF.name = 'hrf';
xBF = spm_get_bf(xBF);
vec = zeros(ncond,npoints);
for cond = 1:ncond
    vec(cond,ons{cond}) = 1;
    for ii=1:duration - 1
        spoint = ons{cond} + ii;
        if spoint <= npoints % prevent onsets from extending beyond data
            vec(cond,spoint) = 1;
        end
    end
    tmpvec = conv(vec(cond,:),xBF.bf,'full');
    tmpvec(npoints+1:end) = [];
    vec(cond,:) = tmpvec;
end

% SHOULD EXCLUDE REST - IMPLICIT BASELINE IS BETTER

% add column of ones for constant, to get intercept from model
vec = [ones(1,npoints); vec]';

% plot design matrix
figure('color','w');
imagesc(vec); axis square;
ylabel('Samples');
xticklabels({'','Constant','',1,'',2,'',3,'',4,''});
xlabel('Conditions');

% channel regression (1st level analysis) - put this in separate function
ch1=nirsdata.oxyData(:,2);
ch1=ch1-mean(ch1);
[stat.b,stat.r2,stat.SEb,stat.tvals,stat.pvals,stat.e] = multregr(vec,ch1);

% prewhitening or coloring (AR1, probably higher) needs to go somewhere,
% probably separately. I think we can use ar.m function here if installed.
% see https://mandymejia.com/2016/11/06/how-to-efficiently-prewhiten-fmri-timeseries-the-right-way/

order = 1;
model = ar(stat.e,1,'ls');
coeff = polydata(model); coeff = coeff(order + 1);
A = diag(ones(order,1),0);

% take a look at nirs-toolbox ar_irls lines 132 - 149, create whitening
% filters, apply to design matrix, apply to data, refit. They use robust
% regression.
