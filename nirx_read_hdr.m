function nirx = nirx_read_hdr(file,varargin)
% function to read NIRx .hdr file
% will optionally make a corrected header after application of a threshold
% on the gain matrix to remove bad channels
%
% file = .hdr file to read
% varargin, can use a threshold if supplying more than 1 arg

fprintf('Reading %s...\n', file);
if nargin > 1
    threshold = varargin{1};
    newfile = true;
else
    threshold = 8; % max gain = no threshold applied
    newfile = false;
end

% load file
if exist(file,'file')
    fp = fopen(file);
else
    error('File not found!');
end

% read file information
C = readtext(file); % new way, ultimately replace rest of line by line
C = C(:,1);
exp = '=';
for ii=1:length(C)
    [hit, nohit] = regexp(char(C{ii}),exp,'match','split');
    if ~isempty(hit)
        switch(nohit{1})
            case 'Sources'
                nirx.sources = str2num(nohit{2});
            case 'Detectors'
                nirx.detectors = str2num(nohit{2});
            case 'Steps'
                nirx.steps = str2num(nohit{2});
            case 'Wavelengths'
                nirx.wl = str2num(strrep(nohit{2},'"',''));
            case 'SamplingRate'
                nirx.sr = str2num(strrep(nohit{2},'"',''));
            case 'NIRStar'
                nirx.ver =  str2num(strrep(nohit{2},'"',''));
            case 'Device'
                nirx.device =  strrep(nohit{2},'"','');
            case 'FileName'
                nirx.file = strrep(nohit{2},'"','');
            case 'ChanDis'
                nirx.dist = str2num(strrep(nohit{2},'"',''));
            case 'ModAmp'
                nirx.mod = str2num(strrep(nohit{2},'"',''));
            case 'Source'
                nirx.source = strrep(nohit{2},'"','');
            case 'Mod'
                nirx.mod = 'Human Subject';
            case 'Subject'
                nirx.sub = str2num(nohit{2});
            case 'AnIns'
                nirx.anins = str2num(nohit{2});
            case 'TrigIns'
                nirx.trigin = str2num(nohit{2});
            case 'TrigOuts'
                nirx.trigout = str2num(nohit{2});
            case 'Threshold'
                nirx.thres = str2num(strrep(nohit{2},'"',''));
            case 'StimulusType'
                nirx.stimtype = strrep(nohit{2},'"','');
            case 'Notes'
                nirx.notes = strrep(nohit{2},'"','');
            otherwise
                % nothing
        end
    end
end

% S-D-Key: note - something is wrong with the nirx S-D-Key. It has more
% channels combined than are actually possible given nsource*ndetector
% pairings
clear C;
C=fileread(file);
exp = 'S-D-Key="(\w+).*?"';
[tline, ~] = regexp(C,exp,'match','tokens');
tline = char(tline);
indx_se = strfind(tline, '"');
indx_comma = strfind(tline, ',');
indx_colon = strfind(tline, ':');
str_ch = {};
nch = length(indx_colon);
str_ch{1} = tline(1,indx_se(1)+1:indx_colon(1)-1);
str_ch{nch} = tline(1,indx_comma(end-1)+1:indx_colon(end)-1);
for jj = 2:nch-1
    str_ch{jj} = tline(1,indx_comma(jj-1)+1:indx_colon(jj)-1); 
end
ch_sd = [];
for jj = 1:nch
    str_chconf = str_ch{jj};
    indx = strfind(str_chconf, '-');
    num_s = str2num(str_chconf(1:indx-1));
    num_d = str2num(str_chconf(indx+1:end));
    ch_sd(jj, 1) = num_s; % source
    ch_sd(jj, 2) = num_d; % detector
end
nirx.SDkey = str_ch;

% loop through line by line to process other info
for ii=1:7
    junk = fgetl(fp);
end
search_strings = {'S-D-Mask','Gains','Events'};
while ~feof(fp)
    line = fgetl(fp);
    loc  = find(strncmp(line,search_strings,5));
    if ~isempty(loc)
        tofind = '#';
        ind = 1;
        line = fgetl(fp);
        switch loc
            case 1
                while isempty(strfind(line,tofind))
                    nums = textscan(line,'%d');
                    SD(ind,:) = nums{1}';
                    ind = ind + 1;
                    line = fgetl(fp);
                end
                nirx.SDmask  = SD;
            case 2
                while isempty(strfind(line,tofind))
                    nums = textscan(line,'%d');
                    G(ind,:) = nums{1}';
                    ind = ind + 1;
                    line = fgetl(fp);
                end
                nirx.gains   = G;
            case 3 % some header files (newer?) do not have events
                while isempty(strfind(line,tofind))
                    tmp = textscan(line,'%f\t%d\t%d');
                    E(ind).time = tmp{1};
                    E(ind).code = tmp{2};
                    E(ind).samp = tmp{3};
                    ind = ind + 1;
                    line = fgetl(fp);
                end
                if ~exist('E','var')
                    % do nothing for now
                else
                    nirx.events   = E';
                end
                % FIXME: just switch to reading the evt files here
        end
    end
end
ind         = find(SD);
good_ind    = find(nirx.gains(ind) <= threshold);
new_mask    = zeros(size(nirx.gains));
new_mask(ind(good_ind)) = 1;
[S,D]       = ind2sub(size(SD),ind(good_ind)); % S and D are indices for non-masked chans
[S, sind]   = sort(S);
D           = D(sind);
nirx.SDpairs = [S D];
nirx.nchan  = size(nirx.SDpairs,1);
nirx.chnums = good_ind;
nirx.maskind = ind;

fclose(fp);

% read entire original file into string and use regexp to replace mask
if newfile
    orig = fileread(file); 
    totrim = 'S-D-Mask="#';
    [starti,endi]=regexpi(orig,['\' totrim '(.*?)\#']); % finds mask indices
    [~,nam,ext]=fileparts(file);
    fp = fopen([nam '_corrected' ext],'w');
    fprintf(fp,'%s\n',orig(1:starti+11));
    for ii=1:size(nirx.SDkey,1)
        for jj=1:size(nirx.SDkey,2)
            if jj == size(nirx.SDkey,2)
                fprintf(fp,'%s\n', num2str(new_mask(ii,jj)));
            else
                fprintf(fp,'%s\t', num2str(new_mask(ii,jj)));
            end
        end
    end
    fprintf(fp,'%s',orig(endi:end));
    fclose(fp);
end