% you can loop this over many subjects, but should make sure each has
% her/his own ch_config.txt and optode_positions.csv in their directories

% NOTE: this script does not delete optodes it interpolates them. If you
% have lots of bad optodes in your data set, you should delete them to
% avoid extrapolation error

file = 'pilot1-2017-04-09_001';
bad_sources = [1,19,48];
bad_detectors = 8;
threshold = 7;
distances = [15 55];
ma_length = 8;
highcut = .01;

% determine good channels based on distance
[~,~,~]=nirx_chan_dist(file,distances,'all','yes');
[~,~,ch_stats]=nirx_chan_dist([file '_dsel'],distances,'mask','no');
save([file '_ch_stats'],'ch_stats');

% find the bad channels formed by bad sources/detectors
hdr = nirx_read_hdr([file '_dsel.hdr']);
sind = [];
dind = [];
for ii=1:length(bad_sources)
    sind = [sind; find(hdr.SDpairs(:,1) == bad_sources(ii))];
end
for ii=1:length(bad_detectors)
    dind = [dind; find(hdr.SDpairs(:,2) == bad_detectors(ii))];
end
bind = unique([sind; dind]);

% interpolate channels based on bad channels
nirx_interpolate_chans([file '_dsel'],'optode_positions.csv',...
    'channel',bind);

% interpolate channels based on bad gains
nirx_interpolate_chans([file '_dsel_cint'],'optode_positions.csv',...
    'threshold',threshold);

% filter the dataset
hdr = nirx_read_hdr([file '_dsel_cint_gint.hdr']);
[raw,~,~,~]=nirx_read_wl([file '_dsel_cint_gint'],hdr,'all');
maraw=nirx_filter(raw,hdr,'moving',ma_length);
maraw=nirx_filter(maraw,hdr,'high',highcut);
nirx_write_wl([file '_dsel_cint_gint_filt'],maraw);
nirx_write_hdr([file '_dsel_cint_gint_filt.hdr'],hdr);