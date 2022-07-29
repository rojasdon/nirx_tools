% script to read/plot signal quality metrics without running spm_fnirs. If
% spm_fnirs has been run, script_plot_optode_gains.m can be used.

% defaults
hdr_file = 'NIRS-2017-05-02_001_dsel.hdr';
mask = true; % false if you do not want to apply mask from NIRStar software

% read file
hdr = nirx_read_hdr(hdr_file);
gains = hdr.gains;

% apply mask if requested
if mask
    maskind = find(hdr.SDmask == 0);
    gains(maskind) = NaN;
end

% quality measure, per NIRx (see manual Table 2)
ind = find(gains >= 1 & gains <= 6);
quality = gains;
quality(ind) = 4; % excellent
ind = find(gains == 7); % acceptable
quality(ind) = 3;
ind = find(gains == 0 | gains == 8); % critical or lost
quality(ind) = 2;

% note that lost channels are not shown separately from critical for
% compatibility with older NIRStar acquisitions where noise measures not
% saved to hdr file. Gain alone does not distinguish those two cases.

% plot gains
figure('color','w');
imagesc(gains);
axis image;
xlabel('Sources'); ylabel('Detectors');
h1 = colorbar;
h1.Label.String = 'Gain';
colormap jet;


% plot quality scale as shown in NIRStar
figure('color','w');
imagesc(quality);
axis image;
xlabel('Sources'); ylabel('Detectors');
h1 = colorbar('Ticks',[2,3,4],'TickLabels',...
    {'Critical/Lost','Acceptable','Excellent'});
h1.Label.String = 'Quality Metric';
colorscale = [1 0 0;
              1 1 0;
              0 1 0];
colormap(colorscale);
        