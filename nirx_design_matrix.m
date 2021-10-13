% create/visualize experimental design
clear;

duration = [20 20 20 8]; % seconds

basename = 'NIRS-2021-09-28_001';
[onsets, vals]=nirx_read_evt([basename '.evt']);
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
end

% task vectors and convolution with hrf
[hrf, p] = spm_hrf(hdr.sr); % check with spm_fnirs code
vec = zeros(ncond,npoints);
for cond = 1:ncond
    vec(cond,ons{cond}) = 1;
    for ii=1:duration(cond) - 1
        vec(cond,ons{cond} + ii) = 1;
        tmpvec = conv(vec(cond,:),hrf,'full');
        cut = length(tmpvec) - length(vec(cond,:));
        tmpvec = tmpvec(1:end-cut);
        vec(cond,:) = tmpvec;
    end
end

% add column of ones for constant, to get intercept from model
vec = [ones(1,npoints); vec]';

% plot design matrix
figure('color','w');
imagesc(vec); axis square;
ylabel('Samples');
xticklabels({'Constant',1,2,3,4});
xlabel('Conditions');

% channel regression (1st level analysis) - put this in separate function
ch1=nirsdata.oxyData(:,1);
[stat.b,stat.r2,stat.SEb,stat.tvals,stat.pvals,stat.e] = multregr(vec,ch1);



