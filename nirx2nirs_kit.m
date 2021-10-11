% nirx to NIRS_KIT converter
% First version 10/03/2021
% Don Rojas, Ph.D.
%
% 
clear;

% defaults
baseline = 50; % baseline in samples

% load nirx data
filebase = 'NIRS-2021-09-28_001';
hdr = nirx_read_hdr([filebase '.hdr']);
[raw, cols, S,D] = nirx_read_wl(filebase,hdr);

% read events
[onsets, vals] = nirx_read_evt([filebase '.evt']);

% convert optical measurements to hemoglobin units
% probably not correct - see NR_convert.m NIRx part
nsamp = size(raw,2);
hb = zeros(nsamp-50,hdr.nchan);
hbo = hb;
hbt = hbo;
for chan = 1:hdr.nchan
    [hb(:,chan), hbo(:,chan), hbt(:,chan)] = mes2hb(squeeze(raw(:,:,chan))', hdr.wl, [1 50]);
end

% create NIRS_KIT structure
nirsdata = [];
nirsdata.oxyData = hbo;
nirsdata.dxyData = hb;
nirsdata.totalData = hbt;
nirsdata.T = 1/hdr.sr;
nirsdata.nch = hdr.nchan;
vector_onsets = zeros(nsamp,1);
vector_onsets(onsets) = 1;
nirsdata.vector_onsets = vector_onsets;
nirsdata.probeset = {};
nirsdata.subject = filebase;
nirsdata.system = 'NIRX';
nirsdata.probe2d = {};
nirsdata.probe3d = {};

% save
save([filebase '.mat'],'nirsdata');

