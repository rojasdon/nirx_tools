% create/visualize experimental design
clear;

duration = 20; % seconds

basename = 'NIRS-2021-09-28_001';
[onsets, vals]=nirx_read_evt([basename '.evt']);
hdr = nirx_read_hdr([basename '.hdr']);
[raw,~,~,~] = nirx_read_wl(basename,hdr);
npoints = size(raw,2);

% duration to samples from seconds
duration = round(duration/(1/hdr.sr));

% conditions
ucond = unique(vals);
ncond = length(ucond);
for ii=1:ncond
    ons{ii} = onsets(vals == ucond(ii));
end

% task vectors
vec = zeros(ncond,npoints);
for cond = 1:ncond
    vec(cond,ons{cond}) = 1;
    for ii=1:duration - 1
        vec(cond,ons{cond} + ii) = 1;
    end
end

% plot design matrix
figure('color','w');
imagesc(vec');


