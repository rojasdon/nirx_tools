% nirx to NIRS_KIT converter
% First version 10/12/2021
% Don Rojas, Ph.D.
%
% Description: reads nirx data formats, converts od to hb concentration via 
% modified beer-lambert law, corrects for nearest short channels, and
% writes to nirs_kit formatted .mat file
% TODO: turn this into a function that can be scripted
clear;

% Important for OD to HB conversion
age = 23; % age in years

% required files
posfile = 'optode_positions.csv';
chconfig = 'ch_config.txt';

% load nirx data
filebase = 'NIRS-2021-09-28_001';
hdr = nirx_read_hdr([filebase '.hdr']);
[raw, cols, S,D] = nirx_read_wl(filebase,hdr);
nchans = size(raw,3);
npoints = size(raw,2);

% read events
[onsets, vals] = nirx_read_evt([filebase '.evt']);

% convert optical measurements to hemoglobin units
ec1 = nirx_ecoeff(hdr.wl(1));
ec2 = nirx_ecoeff(hdr.wl(2));
ec  = [ec1;ec2];
dpf = nirx_DPF([hdr.wl(1) hdr.wl(2)],age);
hbo = zeros(nchans,npoints);
hbr = hbo;
hbt = hbo;
[sd_dist,~,~] = nirx_sd_dist(filebase,[0 70],'mask','no'); % we don't care about good/bad here
for chn = 1:nchans
    od = squeeze(raw(:,:,chn));
    [hbo(chn,:),hbr(chn,:),hbt(chn,:)] = nirx_mbll(od,dpf,ec);
    % alternatively, use sd_dist in mbll call
    % [hbo(chn,:),hbr(chn,:),hbt(chn,:)] = nirx_mbll(od,dpf,ec,sd_dist(chn));
end

% short channel regression to correct for scalp influences
[heads,ids,pos] = nirx_read_optpos(posfile);
chns = nirx_read_chconfig(chconfig);
chanpos = nirx_compute_chanlocs(ids,pos,chns);
nb = nirx_nearest_neighbors(chanpos);
nld = length(hdr.longSDindices);
hbo_c = zeros(nld,npoints);
hbr_c = hbo_c;
hbt_c = hbo_c;
for chn = 1:nld
    sdi = nirx_nearest_short(hdr.longSDindices(chn),nb,hdr);
    sdo = hbo(sdi,:);
    sdr = hbr(sdi,:);
    hbo_c(chn,:) = nirx_short_regression(hbo(hdr.longSDindices(chn),:),sdo);
    hbr_c(chn,:) = nirx_short_regression(hbr(hdr.longSDindices(chn),:),sdr);
    hbt_c(chn,:) = hbo_c(chn,:) + hbr_c(chn,:);
end

% plot to compare pre/post short channel regression
figure('color','w');
subplot(2,1,1);
plot(hbo(1:4,:)');
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'1o','2o','3o','4o'});
title('Original (o) channels (HbO)');
hold on;
subplot(2,1,2);
plot(hbo_c(1:4,:)');
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'1c','2c','3c','4c'});
title('Corrected (c) channels (HbO)');

% remove dc offsets
m_hbo_c = mean(hbo_c,2);
m_hbr_c = mean(hbr_c,2);
m_hbt_c = mean(hbt_c,2);
hbo_c = hbo_c - repmat(m_hbo_c,1,npoints);
hbr_c = hbr_c - repmat(m_hbr_c,1,npoints);
hbt_c = hbt_c - repmat(m_hbt_c,1,npoints);

% create NIRS_KIT structure
nirsdata = [];
nirsdata.oxyData = hbo_c';
nirsdata.dxyData = hbr_c';
nirsdata.totalData = hbt_c';
nirsdata.T = 1/hdr.sr;
nirsdata.nch = nld;
vector_onsets = zeros(npoints,1);
vector_onsets(onsets) = 1;
nirsdata.vector_onsets = vector_onsets;
nirsdata.probeset = {};
nirsdata.subject = filebase;
nirsdata.system = 'NIRX';
nirsdata.probe2d = {};
nirsdata.probe3d = {};

% save
save([filebase '.mat'],'nirsdata');

