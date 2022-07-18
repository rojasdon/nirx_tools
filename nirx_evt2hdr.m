function nirx_evt2hdr(evtfile,hdrfile,backupfiles)
% PURPOSE: To update header file events with evt file events, in case
% customization of event file is done after acquisition
% AUTHOR: D. Rojas
% INPUTS:   1. evtfile, name of event file (.evt ext)
%           2. hdrfile, name of header file (.hdr ext)
%           3. backupfiles, true|false, makes copy of
%           original header as _original_backup.hdr
% OUTPUTS: None on command line, writes new hdr file
% HISTORY: 07/18/2022 - first working version

[ons,val] = nirx_read_evt(evtfile);

% pseudocode

% make a copy of the original header file

% read header as text, find insertion point or range of insertion in data

% start writing back to insertion point

% at insertion, replace/add something as follows, looping through onsets

fprintf(fp,'%.2f\t%d\t%d\n',ons(line)*1/hdr.sr,val(line),ons(line));

% write the remainder of the header string


end