% script to apply some basic preprocessing,
% applying the following preprocessing steps:

% 1. OD to hemoglobin conversion (modified beer lambert law)
% 2. Determination of bad channels using SCI
% 3. Motion correction
% 4. Filtering
% 5. Production of quality assurance figures

% if applying to your own data, make sure assumptions are correct on file
% naming and constants in basic preamble
clear;

%% Preamble

% basic constants/definitions
qa_suffix = 'qa.jpg'; % suffix for quality assurance figures
qamap = [1 1 1
         1 0 0
         1 1 0
         0 1 0]; % colorscale for quality assurance figure
screen = get(0,'screensize'); % for setting figure size and location
screen_h = screen(4);
screen_w = screen(3);

% filter bands
MW_band = [.07 .14]; % Mayer wave band
HR_band = [.01 .3]; % Hemodynamic response band
         
% Important for OD to HB conversion
age = 20; % age in years, should alter to actual age in script

% required files
posfile = 'optode_positions.csv';
chconfig = 'ch_config.txt';

% load nirx data
filebase = 'NIRS-2023-03-31_001';
hdr = nirx_read_hdr([filebase '.hdr']);
[raw, cols, S,D] = nirx_read_wl(filebase,hdr);
nchans = size(raw,3);
npoints = size(raw,2);

% read channel configuration
chpairs = nirx_read_chconfig(chconfig);

%% basic preprocessing
% raw intensity to optical density
od = nirx_OD(raw);
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
    tmp = squeeze(od(:,:,chn));
    sd = chpairs(chn,2:3);
    cdist = sd_dist{sd(1)}(sd(2));
    % MBLL, giving channel distance in cm
    [hbo(chn,:),hbr(chn,:),hbt(chn,:)] = nirx_mbll(tmp,dpf,ec,cdist/10); % Beer-Lambert Law
end

% signal quality computation - here to exclude bad short channels, but
% later for long channels too
[bad,sci] = nirx_signal_quality_sci(hdr,raw);
bad_shorts = find(ismember(hdr.shortSDindices,bad));

% motion correction using TDDR or other method
hbo_mcorr = TDDR(hbo',hdr.sr);
hbr_mcorr = TDDR(hbr',hdr.sr);
hbo_mcorr = hbo_mcorr';
hbr_mcorr = hbr_mcorr';

% filter - make sure the high cutoff is higher than your block/task
% repetition rate for your HR band or you will be filtering out your wanted 
% brain signals!
hbo_HR = nirx_filter(hbo_mcorr,hdr,'band',HR_band,'order',4);
hbr_HR = nirx_filter(hbr_mcorr,hdr,'band',HR_band,'order',4);
hbo_MW = nirx_filter(hbo_mcorr,hdr,'band',MW_band,'order',4);
hbr_MW = nirx_filter(hbr_mcorr,hdr,'band',MW_band,'order',4);

% remove dc offsets, in case of uncorrected hb just for plotting purposes
hbo_HR = nirx_offset(hbo_HR);
hbr_HR = nirx_offset(hbr_HR);
hbo_MW = nirx_offset(hbo_MW);
hbr_MW = nirx_offset(hbo_MW);
hbo_mcorr = nirx_offset(hbo_mcorr);
hbr_mcorr = nirx_offset(hbr_mcorr);
hbt_HR = hbr_HR + hbo_HR;

% nearest short channel regressors - compute and save for later use in GLM
[heads,ids,pos] = nirx_read_optpos(posfile);
chns = nirx_read_chconfig(chconfig);
[longpos,shortpos] = nirx_compute_chanlocs(ids,pos,chns,hdr.shortdetindex);
nld = length(hdr.longSDindices);
scnn = nirx_nearest_short(shortpos,longpos,hdr,bad_shorts);
nearest_hr_sd = zeros(nld,npoints,2);
nearest_mw_sd = zeros(nld,npoints,2);
for chn = 1:nld
    nearest_hr_sd(chn,:,1) = hbo_HR(scnn(chn),:)';
    nearest_hr_sd(chn,:,2) = hbr_HR(scnn(chn),:)';
    nearest_mw_sd(chn,:,1) = hbo_MW(scnn(chn),:)';
    nearest_mw_sd(chn,:,2) = hbr_MW(scnn(chn),:)';
end

% extract all the short channels for GLM/PCA
hbo_HR_short = hbo_HR(hdr.shortSDindices,:);
hbr_HR_short = hbr_HR(hdr.shortSDindices,:);
hbo_MW_short = hbo_HR(hdr.shortSDindices,:);
hbr_MW_short = hbr_HR(hdr.shortSDindices,:);

%% Plotting

% plot to compare pre/post processing
longchans = find(ismember(hdr.ch_type,'long'));
h = figure('color','w');
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
subplot(3,1,1);
plot(hbo(longchans(1),:)'); axis tight;
hold on;
plot(hbr(longchans(1),:)'); axis tight;
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'HbO','HbR'});
title('MBLL Only - Channel 1');
subplot(3,1,2);
plot(hbo_mcorr(longchans(1),:)'); axis tight;
hold on;
plot(hbr_mcorr(longchans(1),:)'); axis tight;
legend({'HbO','HbR'});
title('Motion Corrected - Channel 1');
subplot(3,1,3);
plot(hbo_HR(longchans(1),:)'); axis tight;
hold on;
plot(hbr_HR(longchans(1),:)'); axis tight;
legend({'HbO','HbR'});
title('MBLL+Motion+Filter - Channel 1');
print(h, '-djpeg', [filebase '_Preprocessing' qa_suffix]);

% plot all channels with no corrections
h = figure('color','w'); hold on; title('All Channels HbO2 no corrections, only MBLL');
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
spacing = 2;
for chn=1:length(longchans)
    plot(hbo(longchans(chn),:)' + (chn*spacing)); axis tight;
end
yticklabels(string(5:5:50));
xlabel('Samples'); ylabel({'\Delta hemoglobin (\muM)';'Channel'});
print(h, '-djpeg', [filebase '_all_MBLL_only' qa_suffix]);

% plot all channels, motion corrected + filtered
h = figure('color','w'); hold on; title('All Channels HbO2 Motion + Filtering');
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
spacing = 2;
for chn=1:length(longchans)
    plot(hbo_HR(chn,:)' + (chn*spacing)); axis tight;
end
yticklabels(string(5:5:50));
xlabel('Samples'); ylabel({'\Delta hemoglobin (\muM)';'Channel'});
print(h, '-djpeg', [filebase '_all_Motion+Filter' qa_suffix]);

%% Save data

% save interim processed data
save([filebase '_hb_sd.mat'],'hbo_HR','hbr_HR','hbt_HR','hbo_MW','hbr_MW','bad','sci',...
    'nearest_hr_sd','nearest_mw_sd','hbo_HR_short','hbr_HR_short','hbo_MW_short','hbr_MW_short');