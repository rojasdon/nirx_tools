function nirx_evt2hdr(evtfile,hdrfile)
% PURPOSE: To update header file events with evt file events, in case
% customization of event file is done after acquisition
% AUTHOR: D. Rojas
% INPUTS:   1. evtfile, name of event file (.evt ext)
%           2. hdrfile, name of header file (.hdr ext)
%           3. backupfiles, true|false, makes copy of
%           original header as _original_backup.hdr
% OUTPUTS: None on command line, writes new hdr file
% HISTORY: 07/18/2022 - first working version

% read the event file
[ons,val] = nirx_read_evt(evtfile);

% read in the header file as single cell array and as a hdr struct
hdr = nirx_read_hdr(hdrfile);
s = fileread(hdrfile);

% first, find the event part of the header
start_expr = "\[Markers\]";
start = regexp(s,start_expr);
stop_expr = '\#"';
tmp = regexp(s,stop_expr); % candidate endings
stop = min(tmp(tmp > start)) + 1; % first end after start

% divide the string into pre and post marker parts
s_pre = s(1:start-1);
s_post = s(stop+1:end);

% make copy of old file and create new header file
[~,base,ext] = fileparts(hdrfile);
copyfile(hdrfile,[base '_backup' ext]);
delete(hdrfile);
fp = fopen(hdrfile,"w");

% start writing back to insertion point
fprintf(fp,'%s\n',s_pre);

% at insertion, replace/add something as follows, looping through onsets
fprintf(fp,'[Markers]\n');
fprintf(fp,'Events="#\n');
for line=1:length(ons)
    fprintf(fp,'%.2f\t%d\t%d\n',ons(line)*1/hdr.sr,val(line),ons(line));
end
fprintf(fp,'#"\n');

% write the remainder of the header string
fprintf(fp,s_post);

% close file
fclose(fp);