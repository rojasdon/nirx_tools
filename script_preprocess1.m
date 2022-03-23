% script to apply some basic preprocessing,
% applying the following preprocessing steps:

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
         0 1 0]; % colorscale for quality assurance figure
screen = get(0,'screensize'); % for setting figure size and location
screen_h = screen(4);
screen_w = screen(3);
         
% Important for OD to HB conversion
age = 30; % age in years, should alter to actual age in script

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
% [onsets, vals] = nirx_read_evt([filebase '_corrected.evt']);

% read channel configuration
chpairs = nirx_read_chconfig(chconfig);

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
    sd = chpairs(chn,2:3);
    cdist = sd_dist{sd(1)}(sd(2));
    % MBLL, giving channel distance in cm
    [hbo(chn,:),hbr(chn,:),hbt(chn,:)] = nirx_mbll(od,dpf,ec,cdist/10); % Beer-Lambert Law
end

% motion correction using CBSI method - need to do this prior to short
% regression to avoid introducing motion from short channels into long
% channels
% [hbo_mcorr,hbr_mcorr,hbt_mcorr]=nirx_motion_cbsi(hbo,hbr);
hbo_mcorr = nirx_motion_spline(hbo,hdr);
hbr_mcorr = nirx_motion_spline(hbr,hdr);

% short channel regression to correct for scalp influences
[heads,ids,pos] = nirx_read_optpos(posfile);
chns = nirx_read_chconfig(chconfig);
[longpos,shortpos] = nirx_compute_chanlocs(ids,pos,chns,hdr.shortdetindex);
nld = length(hdr.longSDindices);
scnn = nirx_nearest_short(shortpos,longpos,hdr);
hbo_c = zeros(nld,npoints);
scalp_o = hbo_c;
scalp_r = hbo_c;
hbr_c = hbo_c;
hbt_c = hbo_c;
for chn = 1:nld
    fprintf('%d\n',chn)
    sdo = hbo_mcorr(scnn(chn),:);
    sdr = hbr_mcorr(scnn(chn),:);
    % do regression, save scalp signals for plotting
    [hbo_c(chn,:),~,scalp_hbo(chn,:)] = nirx_short_regression(hbo_mcorr(hdr.longSDindices(chn),:),sdo);
    [hbr_c(chn,:),~,scalp_hbr(chn,:)] = nirx_short_regression(hbr_mcorr(hdr.longSDindices(chn),:),sdr);
    hbt_c(chn,:) = hbo_c(chn,:) + hbr_c(chn,:);
end

% low pass filter
hbo_f = nirx_filter(hbo_c,hdr,'low',.5,'order',4);
hbr_f = nirx_filter(hbr_c,hdr,'low',.5,'order',4);

% remove dc offsets, in case of uncorrected hb just for plotting purposes
hbo_o = nirx_offset(hbo);
hbr_o = nirx_offset(hbr);
hbo_co = nirx_offset(hbo_c);
hbr_co = nirx_offset(hbr_c);
hbo_mcorr_o = nirx_offset(hbo_mcorr);
hbr_mcorr_o = nirx_offset(hbr_mcorr);
scalp_hbo_o = nirx_offset(scalp_hbo);
scalp_hbr_o = nirx_offset(scalp_hbr);
hbo_f_o = nirx_offset(hbo_c);
hbr_f_o = nirx_offset(hbr_c);

% plot to compare pre/post short channel regression on first long
% channel, along with estimated scalp signal
longchans = find(ismember(hdr.ch_type,'long'));
h = figure('color','w');
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
subplot(2,1,1);
plot(hbo_o(longchans(1),:)'+.002); axis tight;
hold on;
plot(scalp_hbo_o(longchans(1),:)'+.001);
plot(hbo_co(longchans(1),:)');
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'Original','Scalp Estimate','Corrected'});
title('HbO Channel 1');
subplot(2,1,2);
plot(hbr_o(longchans(1),:)'+.002); axis tight;
hold on;
plot(scalp_hbr_o(longchans(1),:)'+.001);
plot(hbr_co(longchans(1),:)');
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'Original','Scalp Estimate','Corrected'});
title('HbR Channel 1');
print(h, '-djpeg', [filebase '_shortcorr' qa_suffix]);

% plot to compare motion correction only to motion + short channel corrected
% signals
h = figure('color','w');
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
subplot(2,1,1);
plot(hbo_mcorr_o(longchans(1),:)'+.002); axis tight;
hold on;
plot(hbo_co(longchans(1),:)');
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'CBSI Only','Short + Motion'});
title('HbO Channel 1');
subplot(2,1,2);
plot(hbr_mcorr_o(longchans(1),:)'+.002); axis tight;
hold on;
plot(hbr_co(longchans(1),:)');
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'CBSI Only','Short + Motion'});
title('HbR Channel 1');
print(h, '-djpeg', [filebase '_motion+short' qa_suffix]);

% plot all channels with no corrections
h = figure('color','w'); hold on; 
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
scaling = 1e3; spacing = 2;
for chn=1:length(longchans)
    plot(hbo_o(longchans(chn),:)' * scaling + (chn*spacing)); axis tight;
end
yticklabels(string(5:5:50));
xlabel('Samples'); ylabel({'\Delta hemoglobin (\muM)';'Channel'});
print(h, '-djpeg', [filebase '_all_uncorrected' qa_suffix]);

% plot all channels, short channel + motion corrected + filtered
h = figure('color','w'); hold on; 
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
scaling = 1e3; spacing = 2;
for chn=1:length(longchans)
    plot(hbo_f_o(chn,:)' * scaling + (chn*spacing)); axis tight;
end
yticklabels(string(5:5:50));
xlabel('Samples'); ylabel({'\Delta hemoglobin (\muM)';'Channel'});
print(h, '-djpeg', [filebase '_all_corrected' qa_suffix]);

% signal quality computation
q = nirx_signal_quality(hdr,raw); % todo: need to use this to exclude shorts from regression

% signal quality figure
h = figure('color','w');
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
imagesc(q.quality); caxis([0 3]);
title('NIRx Quality Metric Map');
xlabel('Channels');
ylabel('Wavelength (nM)');
yticklabels({'',hdr.wl(1),'',hdr.wl(2),''})
colormap(qamap);
colorbar('Ticks',[0,1,2,3,4],...
         'TickLabels',{'Lost','Critical','Acceptable','Excellent'})
print(h, '-djpeg', [filebase '_qamap' qa_suffix]);


%% should add in figure comparing pre and post processing on all short channels %%

% save interim processed data
hbt_mcorr_o = hbo_mcorr_o + hbr_mcorr_o;
save([filebase '_hb_sd.mat'],'hbo_mcorr_o','hbr_mcorr_o','hbt_mcorr_o','q');