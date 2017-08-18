% spm-based GUI input script for producing multi-condition event mat file
% for spm_fnirs

% Author: Don Rojas, Ph.D.

% prompt for event file
event_file              = spm_select(1,'any','Select NIRx Event File',...
                      '',pwd,'^.*\.evt$');
[onsetvec, trigvals]    = nirx_read_evt(event_file);
trigs                   = unique(trigvals);
nconditions             = length(trigs);
names                   = cell(1,nconditions);
durations               = zeros(1,nconditions);

% input is in seconds or scans/samples?
inp = spm_input('Onsets/Durations scaling?','','b',{'Seconds','Scans'},1:2,'');

% scale input to seconds if requested
if inp == 1
    hfile = spm_select(1,'any','Select NIRx hdr file','',pwd,'^.*\.hdr$');
    hdr = nirx_read_hdr(hfile);
    sr = 1/hdr.sr;
    onsetvec = sr * onsetvec;
end

% get condition names and durations
for ii = 1:nconditions
    names{ii} = spm_input(['Condition ' num2str(trigs(ii)) ' name?'],'+1','s','');
    durations(ii) = str2num(spm_input(['Condition ' num2str(ii) ' duration?'],'+1','s',''));
end
    
outfile = spm_input('Output file name? ','+1','s','');
write_condition_file(outfile,names,trigs,trigvals,onsetvec,durations);