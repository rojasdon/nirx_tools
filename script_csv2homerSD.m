% script to convert an spm_fnirs formatted optode position and configuration files 
% into a Homer2 compatible SD file

clear;

% defaults
scale = 'mm';
wavelengths = [760 850];
outfile = 'probes.SD';

% read channel info
csvfile = spm_select(1,'any','Select csv file with optode positions',{},pwd,...
    '.*\.csv$');
chfile = spm_select(1,'any','Select ch_config file with chan info',{},pwd,...
    '^ch_.*\.txt$');
[~,id,pos] = nirx_read_chpos(csvfile);
chns = nirx_read_chconfig(chfile);

% find sources and detectors
sind = [];
dind = [];
for ii=1:length(id)
    name = char(id{ii});
    if name(1) == 'S'
        sind = [sind ii];
    else
        dind = [dind ii];
    end
end

% create SD structure
SD.Lambda = wavelengths;
SD.nDets = length(dind);
SD.nSrcs = length(sind);
SD.DetPos = pos(dind,:);
SD.SrcPos = pos(sind,:);
SD.SpatialUnit = scale;
SD.nDummies = 0;
SD.AnchorList = {};

SD.MeasList = zeros(length(chns),4);
SD.MeasList(:,1:2) = chns(:,2:3);
SD.MeasList(:,3) = ones(length(chns),1);
SD.MeasList(:,4) = ones(length(chns),1); % wl1 
wl2 = SD.MeasList;
wl2(:,4) = ones(length(chns),1) * 2;
SD.MeasList = [SD.MeasList; wl2];
SD.MeasListAct = ones(length(chns)*2,1);
SD.MeasListVis = ones(length(chns)*2,1);

% save
save(outfile,'SD');