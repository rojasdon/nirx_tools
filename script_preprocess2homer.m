% script to apply some basic preprocessing, then export to homer2
% applies the following preprocessing steps:

% 1. OD to hemoglobin conversion (modified beer lambert law)
% 2. Short channel regression using nearest short channel to each long channel
% 3. Production of quality assurance figures

% if applying to your own data, make sure assumptions are correct on file
% naming and constants in basic preamble
clear;

%% PREAMBLE

% basic constants/definitions
qa_suffix = 'qa.jpg'; % suffix for quality assurance figures
qamap = [1 1 1
         1 0 0
         1 1 0
         0 1 0];
         
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
[onsets, vals] = nirx_read_evt([filebase '_corrected.evt']);

%% basic preprocessing
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
    % alternatively, use sd_dist in mbll call (maybe more accurate, if s-d distance is known)
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

% remove dc offsets
m_hbo_c = mean(hbo_c,2);
m_hbr_c = mean(hbr_c,2);
m_hbt_c = mean(hbt_c,2);
hbo_co = hbo_c - repmat(m_hbo_c,1,npoints);
hbr_co = hbr_c - repmat(m_hbr_c,1,npoints);
hbt_co = hbt_c - repmat(m_hbt_c,1,npoints);

% plot to compare pre/post short channel regression and offset correction
h = figure('color','w');
subplot(3,1,1);
plot(hbo(1:4,:)'); axis tight;
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'1','2','3','4'});
title('Uncorrected channels (HbO)');
hold on;
subplot(3,1,2);
plot(hbo_c(1:4,:)'); axis tight; 
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'1','2','3','4'});
title('SD Corrected channels (HbO)');
subplot(3,1,3);
plot(hbo_co(1:4,:)'); axis tight; 
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'1','2','3','4'});
title('SD Corrected channels (HbO), baseline removed');
print(h, '-djpeg', [filebase '_signals' qa_suffix]); close(h);

% signal quality computation
q = nirx_signal_quality(hdr,raw);

% signal quality figure
h = figure('color','w');
imagesc(q.quality);
title('NIRx Quality Metric Map');
xlabel('Channels');
ylabel('Wavelength (nM)');
yticklabels({'',hdr.wl(1),'',hdr.wl(2),''})
colormap(qamap);