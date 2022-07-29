function nirx2homer2(NIRx_foldername, NIRx_basename, SD_filename)

% Code originally based on NIRx2nirs.m version 1.0 by Rob J Cooper, University College London, August 2013

% adapted for batch scripting with minor bug fixing by Don Rojas, Colorado State University

% NOTE: to create the required SD file, use script_csv2homerSD.m

% INPUTS:
%   NIRx_foldername = name of directory with wl1, wl2 and hdr files
%   NIRx_basename = name, w/o extension of files to be found
%   SD_filename = name of SD probe file

% Load SD_file
if ~exist(SD_filename,'file')
    error('SD file does not exist in specified location!');
end
load(SD_filename,'-mat');

% Load wavelength d
wl1_dir = dir(fullfile(NIRx_foldername,[NIRx_basename '*.wl1']));
if isempty(wl1_dir)
    error('ERROR: Cannot find NIRx .wl1 file in selected directory...');
end
wl1 = load([NIRx_foldername '/' wl1_dir(1).name]);
wl2_dir = dir(fullfile(NIRx_foldername,[NIRx_basename '*.wl2']));
if isempty(wl2_dir)
    error('ERROR: Cannot find NIRx .wl2 file in selected directory...'); 
end
wl2 = load([NIRx_foldername '/' wl2_dir(1).name]);
d=[wl1 wl2]; % d matrix from .wl1 and .wl2 files

% Read and interpret .hdr
hdr_dir = dir(fullfile(NIRx_foldername,[NIRx_basename '.hdr']));
if isempty(hdr_dir)
    error('ERROR: Cannot find NIRx header file in selected directory...');
end
fid = fopen([NIRx_foldername '/' hdr_dir(1).name]);
tmp = textscan(fid,'%s','delimiter','\n'); % just read every line
hdr_str = tmp{1};
fclose(fid);

% Find number of sources
keyword = 'Sources=';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)); %This gives cell of hdr_str with keyword
tmp = hdr_str{ind};
NIRx_Sources = str2num(tmp(length(keyword)+1:end));

% Find number of detectors
keyword = 'Detectors=';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)); %This gives cell of hdr_str with keyword
tmp = hdr_str{ind};
NIRx_Detectors = str2num(tmp(length(keyword)+1:end));

% Find Sample rate
keyword = 'SamplingRate=';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)); %This gives cell of hdr_str with keyword
tmp = hdr_str{ind};
fs = str2num(tmp(length(keyword)+1:end));

% Find Active Source-Detector pairs (these will just be ordered by source,
% then detector (so, for example d(:,1) = source 1, det 1 and d(:,2) =
% source 1 det 2 etc.
keyword = 'S-D-Mask="#';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)) + 1; %This gives cell of hdr_str with keyword
tmp = strfind(hdr_str(ind+1:end),'#');
ind2 = find(~cellfun(@isempty,tmp)) - 1;
ind2 = ind + ind2(1);
sd_ind = cell2mat(cellfun(@str2num,hdr_str(ind:ind2),'UniformOutput',0));
sd_ind = sd_ind';
sd_ind = find([sd_ind(:);sd_ind(:)]);
d = d(:,sd_ind);

% Find Event Markers and build S vector
keyword = 'Events="#';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)) + 1; %This gives cell of hdr_str with keyword
tmp = strfind(hdr_str(ind+1:end),'#');
ind2 = find(~cellfun(@isempty,tmp)) - 1;
ind2 = ind + ind2(1);
events = cell2mat(cellfun(@str2num,hdr_str(ind:ind2),'UniformOutput',0));
events = events(:,2:3);
markertypes = unique(events(:,1));
s = zeros(length(d),length(markertypes));
for i = 1:length(markertypes);
    s(events(find(events(:,1)==markertypes(i)),2),i) = 1;
end

% Create t, aux varibles
aux = zeros(length(d),8);
t = 0:1/fs:length(d)/fs - 1/fs;
tIncMan = ones(length(t),1);

outname = fullfile(NIRx_foldername, [NIRx_basename '.nirs']);

fprintf('Saving as %s ...\n',outname);
save(outname,'d','s','t','tIncMan','aux','SD');
