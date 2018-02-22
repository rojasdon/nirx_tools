% spm12-based GUI input script for producing multi-condition event mat file
% for spm_fnirs from nirx .evt file input

% Author: Don Rojas, Ph.D.

% prompt for event file
event_file              = spm_select(1,'any','Select NIRx Event File',...
                      '',pwd,'^.*\.evt$');
[onsetvec, trigvals]    = nirx_read_evt(event_file);
trigs                   = unique(trigvals);
nconditions             = length(trigs);
names                   = cell(1,nconditions);
dur                     = zeros(1,nconditions);

% input is in seconds or scans/samples?
inp = spm_input('Onsets/Durations scaling?','','b',{'Seconds','Scans'},1:2,'');

% scale input to seconds if requested
if inp == 1
    hfile = spm_select(1,'any','Select NIRx hdr file','',pwd,'^.*\.hdr$');
    hdr = nirx_read_hdr(hfile);
    sr = 1/hdr.sr;
    onsetvec = sr * onsetvec;
end

% report 1st trigger
[null,~] = spm_input(num2str(onsetvec(1)),'+1','d!','First trigger time');

% get condition names and durations
for ii = 1:nconditions
    names{ii} = spm_input(['Condition ' num2str(trigs(ii)) ' name?'],'+1','s','');
    dur(ii) = str2num(spm_input(['Condition ' num2str(ii) ' duration?'],'+1','s',''));
end

% onsets
for ii = 1:length(names)
    tind = find(trigvals == trigs(ii));
    onsets{ii} = onsetvec(tind)';
    durations{ii} = repmat(dur(ii),1,length(onsets{ii}));
end

% prompt to remove a condition (such as rest) that has a coded trigger
% value - useful for implicit baseline
inp = spm_input('Do you want to delete a condition/trigger?','','b',{'Yes','No'},1:2,'');
if inp == 1
    [sel,ok] = listdlg('liststring',names,'PromptString','Select Condition(s) to Remove');
    names(sel) = [];
    onsets(sel) = [];
    durations(sel) = [];
end

% save output
outfile = spm_input('Output file name? ','+1','s','');
[null,~] = spm_input(outfile,'+1','d!','Saving file to disk');
save(outfile,'names','onsets','durations');