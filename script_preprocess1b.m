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
         
% Important for OD to HB conversion
age = 30; % age in years, should alter to actual age in script

% required files
posfile = 'optode_positions.csv';
chconfig = 'ch_config.txt';

% load nirx data
filebase = 'NIRS-2021-09-28_002';
hdr = nirx_read_hdr([filebase '.hdr']);
[raw, cols, S,D] = nirx_read_wl(filebase,hdr);
nchans = size(raw,3);
npoints = size(raw,2);

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

% signal quality computation - here to exclude bad short channels, but
% later for long channels too
[bad,sci] = nirx_signal_quality_sci(hdr,raw);
bad_shorts = find(ismember(hdr.shortSDindices,bad));

% motion correction using CBSI or other method - need to do this prior to short
% regression to avoid introducing motion from short channels into long
% channels
[hbo_mcorr,hbr_mcorr,hbt_mcorr]=nirx_motion_cbsi(hbo,hbr);
%hbo_mcorr = nirx_motion_spline(hbof,hdr);
%hbr_mcorr = nirx_motion_spline(hbrf,hdr);
%hbo_mcorr = TDDR(hbof',hdr.sr);
%hbr_mcorr = TDDR(hbrf',hdr.sr);
%hbo_mcorr = hbo_mcorr';
%hbr_mcorr = hbr_mcorr';

% short channel regressors - compute and save for later use in GLM
[heads,ids,pos] = nirx_read_optpos(posfile);
chns = nirx_read_chconfig(chconfig);
[longpos,shortpos] = nirx_compute_chanlocs(ids,pos,chns,hdr.shortdetindex);
nld = length(hdr.longSDindices);
scnn = nirx_nearest_short(shortpos,longpos,hdr,bad_shorts);
nearest_sd = zeros(nld,npoints,2);
for chn = 1:nld
    nearest_sd(chn,:,1) = hbo_mcorr(scnn(chn),:)';
    nearest_sd(chn,:,2) = hbr_mcorr(scnn(chn),:)';
end

% low pass filter - make sure the cutoff is higher than your block/task
% repetition rate or you will be filtering out your wanted brain signals!
hbo_f = nirx_filter(hbo_mcorr,hdr,'low',.2,'order',4);
hbr_f = nirx_filter(hbr_mcorr,hdr,'low',.2,'order',4);

% remove dc offsets, in case of uncorrected hb just for plotting purposes
hbo_o = nirx_offset(hbo);
hbr_o = nirx_offset(hbr);
hbo_mcorr_o = nirx_offset(hbo_mcorr);
hbr_mcorr_o = nirx_offset(hbr_mcorr);
hbo_f_o = nirx_offset(hbo_f);
hbr_f_o = nirx_offset(hbr_f);

%% Plotting

% plot to compare no motion correction to motion correction to filtered
% signals
longchans = find(ismember(hdr.ch_type,'long'));
h = figure('color','w');
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
subplot(3,1,1);
plot(hbo(longchans(1),:)'+.002); axis tight;
hold on;
plot(hbr(longchans(1),:)'); axis tight;
xlabel('Samples'); ylabel('\Delta hemoglobin (\muM)');
legend({'HbO','HbR'});
title('MBLL Only - Channel 1');
subplot(3,1,2);
plot(hbo_mcorr_o(longchans(1),:)'+.002); axis tight;
hold on;
plot(hbr_mcorr_o(longchans(1),:)'); axis tight;
legend({'HbO','HbR'});
title('Motion Corrected - Channel 1');
subplot(3,1,3);
plot(hbo_f_o(longchans(1),:)'+.002); axis tight;
hold on;
plot(hbr_f_o(longchans(1),:)'); axis tight;
legend({'HbO','HbR'});
title('MBLL+Motion+Filter - Channel 1');
print(h, '-djpeg', [filebase '_Preprocessing' qa_suffix]);

% plot all channels with no corrections
h = figure('color','w'); hold on; 
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
scaling = 1e3; spacing = 2;
for chn=1:length(longchans)
    plot(hbo_o(longchans(chn),:)' * scaling + (chn*spacing)); axis tight;
end
yticklabels(string(5:5:50));
xlabel('Samples'); ylabel({'\Delta hemoglobin (\muM)';'Channel'});
print(h, '-djpeg', [filebase '_all_MBLL_only' qa_suffix]);

% plot all channels, short channel + motion corrected + filtered
h = figure('color','w'); hold on; 
set(gcf,'Position',[ceil(screen_w/2) ceil(screen_h/2) 1024 512]);
scaling = 1e3; spacing = 2;
for chn=1:length(longchans)
    plot(hbo_f_o(chn,:)' * scaling + (chn*spacing)); axis tight;
end
yticklabels(string(5:5:50));
xlabel('Samples'); ylabel({'\Delta hemoglobin (\muM)';'Channel'});
print(h, '-djpeg', [filebase '_all_Motion+Filter' qa_suffix]);

% do a better bad channel plot here

%% Save data

% save interim processed data
hbt_mcorr_o = hbo_mcorr_o + hbr_mcorr_o;
save([filebase '_hb_sd.mat'],'hbo_mcorr_o','hbr_mcorr_o','hbt_mcorr_o','bad','sci','nearest_sd');