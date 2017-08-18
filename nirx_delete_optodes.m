function nirx_delete_optodes(basename,Sb,Db,varargin)
% Description:
%   function to delete optodes and channels using them from nirx data
% Inputs:
%   basename = file name w/o extention for files
%   Sb = bad sources, 0 if none
%   Sd = bad detectors, 0 if none
% Optional inputs:
%   'correct' = apply corrections to ch_config.txt and optode_positions.csv
%               this option will backup originals to _odel_orig.txt
% Example: 
%   nirx_delete_optodes('test',[1:4],[2:3],'correct')

% History:
%       07/02/16 - fixed some bugs with indexing of SDpairs and key
%       07/04/16 - fixed issue with ch_config.txt correction

if nargin > 3
    correct_opt=1;
else
    correct_opt=0;
end

% defaults
outext = '_odel';
posfile = 'optode_positions.csv';
chfile = 'ch_config.txt';

% read header and data
hdr = nirx_read_hdr([basename '.hdr']);
raw = nirx_read_wl(basename,hdr,'all');
orig_SDmask = hdr.SDmask;
orig_SDpairs = hdr.SDpairs;

% using a complete mask of nsource * ndetector is necessary, not the S-D
% mask defined for acquisition
fullmask = ones(hdr.sources,hdr.detectors);
ind = find(fullmask);
[Sfull,Dfull] = ind2sub(size(fullmask),ind);
chans = [Sfull Dfull];

% must take S and D vectors to delete all combos with them
% first find their original raw data indices in data from S D indices
chanind = [];
if ~(Sb==0)
    for ii=1:length(Sb)
        tmp = find(chans(:,1)==Sb(ii));
        chanind = [chanind tmp'];
    end
end
if ~(Db==0)
    for ii=1:length(Db)
        tmp = find(chans(:,2)==Db(ii));
        chanind = [chanind tmp'];
    end
end
if isempty(chanind)
    error('Nothing to delete!');
else
    delpairs = [];
    chanind = unique(chanind);
    fprintf('Removing the following S-D pairs:\n');
    for ii=1:length(chanind)
        fprintf('%d: %d %d\n',ii, chans(chanind(ii),1),chans(chanind(ii),2));
        delpairs = [delpairs;chans(chanind(ii),1),chans(chanind(ii),2)];
    end
end

% correct SDkey/mask, gains and header fields
sd_delmask = zeros(size(hdr.SDmask));
if ~(Sb==0)
    hdr.gains(Sb,:)=[];
    sd_delmask(Sb,:) = 1;
    hdr.SDmask(Sb,:) = 0;
    hdr.sources = hdr.sources - length(Sb);
end
if ~(Db==0)
    hdr.gains(:,Db)=[];
    sd_delmask(:,Db) = 1;
    hdr.SDmask(:,Db) = 0;
    hdr.detectors = hdr.detectors - length(Db);
end
delmaskind = find(sd_delmask & orig_SDmask);
[Sdel, Ddel] = ind2sub(size(sd_delmask),delmaskind);
orig_delpairs = [Sdel Ddel];

% correct the S-D Key field
pairind=[];
for ii=1:length(chanind)
    [~,tmp] = ismember(delpairs(ii,:),chans,'rows');
    pairind = [pairind tmp];
end
hdr.SDkey(pairind) = [];

% channels in original mask to delete
oldsdind = [];
for ii=1:length(orig_delpairs)
    [~,tmp] = ismember(orig_delpairs(ii,:),orig_SDpairs,'rows');
    oldsdind = [oldsdind tmp];
end

% correct the mask specific fields
% FIXME: why am I finding SDpairs from orig size SDmask?
hdr.SDmask(:,Db) = [];
hdr.SDmask(Sb,:) = [];
maskind = find(hdr.SDmask);
[Smask, Dmask] = ind2sub(size(hdr.SDmask),maskind);
[Smask, sind]   = sort(Smask);
Dmask = Dmask(sind);
hdr.SDpairs = [Smask Dmask];
hdr.nchan = size(hdr.SDpairs,1);
hdr.chnums = 1:hdr.nchan;
hdr.dist(oldsdind) = [];

% must remove those cols from the full raw
% should all combos be deleted, not just masked? Probably yes.
% I think use pairind var here, not cols ref
newraw=raw;
newraw(:,:,pairind)=[];

% save new raw *.wl files
fprintf('Writing corrected *.wl files...\n');
nirx_write_wl([basename outext],newraw);

% save new *.hdr file
fprintf('Writing new *.hdr file...\n');
hdr.file = [basename outext];
nirx_write_hdr([basename outext '.hdr'],hdr);

% create new optode position and ch_config files (optional)
if correct_opt
    fprintf('Writing new chan config and location files...');
    [fl,lbl, pos] = nirx_read_chpos(posfile);
    sind = [];
    dind = [];
    % sources vs. detectors in posfile
    sind = [];
    dind = [];
    for ii=1:length(lbl)
        if lbl{ii}{1}(1)=='S'
            sind = [sind ii];
        end
    end
    dind = setdiff(1:length(lbl),sind);
    Spos = pos(sind,:);
    Dpos = pos(dind,:);
    Spos(Sb,:)=[];
    Dpos(Db,:)=[];
    [~,nam,ext] = fileparts(posfile);
    movefile(posfile,[nam '_odel_orig' ext]);
    fp = fopen(posfile,'w');
    fprintf(fp,[fl '\n']);
    for ii=1:size(Spos,1)
        fprintf(fp,'%s,%f,%f,%f\n',['S' num2str(ii)],Spos(ii,1),...
            Spos(ii,2),Spos(ii,3));
    end
    for ii=1:size(Dpos,1)
        fprintf(fp,'%s,%f,%f,%f\n',['D' num2str(ii)],Dpos(ii,1),...
            Dpos(ii,2),Dpos(ii,3));
    end
    fclose(fp);
    [~,nam,ext] = fileparts(chfile);
    movefile(chfile,[nam '_odel_orig' ext]);
    nirx_write_ch_config(chfile,hdr);
    fprintf('done\n');
end