% spm12-based GUI input script for producing multi-condition design .mat
% files for spm_fnirs and nirs-kit from nirx .evt file input

% Author: Don Rojas, Ph.D.
% Revisions: 11/13/2021 - now works with NIRS-KIT format

clear;

% prompt for event file
event_file              = spm_select(1,'any','Select NIRx Event File',...
                        '',pwd,'^.*\.evt$');
[onsetvec, trigvals]    = nirx_read_evt(event_file);
trigs                   = unique(trigvals);
nconditions             = length(trigs);
names                   = cell(1,nconditions);
dur                     = zeros(1,nconditions);

% format choice
format = spm_input('Output format?','','b',{'NIRS-KIT','SPM-FNIRS'},1:2,'');

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
spm_input(num2str(onsetvec(1)),'+1','d!','First trigger time');

% get condition names and durations
for ii = 1:nconditions
    names{ii} = spm_input(['Condition ' num2str(trigs(ii)) ' name?'],'+1','s','');
    dur(ii) = str2num(spm_input(['Condition ' num2str(ii) ' duration?'],'+1','s',''));
end
n_conditions = length(names);

% prompt to add a condition, such as an instruction set, that is coded
% only by the condition trigger, not separately. An example is when a block
% of trials is always preceded by an instruction, but the trigger came on
% the instruction, not the trials. In such cases, an offset of the trigger
% can be accomplished here to more correctly align with the stimuli
inp = 0;
inp = spm_input('Do you want to add an offset and model an instruction?','','b',{'Yes','No'},1:2,'');
offset = 0;
if inp == 1
    offset = spm_input('Offset in sec or scans:','+1','e');
    origvec = onsetvec;
    names{end+1} = 'Instruction';
end
onsetvec = onsetvec + offset;

% onsets
for ii = 1:n_conditions
    tind = find(trigvals == trigs(ii));
    onsets{ii} = onsetvec(tind)';
    durations{ii} = repmat(dur(ii),1,length(onsets{ii}));
end
if inp == 1
    onsets{end+1} = origvec';
    durations{end+1} = repmat(offset,1,length(origvec));
end
n_conditions = length(names);

% prompt to remove a condition (such as rest) that has a coded trigger
% value - useful for implicit baseline
inp = 0;
inp = spm_input('Do you want to delete a condition/trigger?','','b',{'Yes','No'},1:2,'');
if inp == 1
    [sel,ok] = listdlg('liststring',names,'PromptString','Select Condition(s) to Remove');
    names(sel) = [];
    onsets(sel) = [];
    durations(sel) = [];
end

% save output
switch format
    case 1 % NIRS-KIT
        [~,base,~] = fileparts(event_file);
        outfile = [base '_task.mat'];
        design_inf = cell(2,nconditions);
        design_inf{1,1} = 'SubID\Condition...';
        for ii=1:nconditions
            design_inf{1,ii+1} = names{ii};
        end
        design_inf{2,1} = base;
        for ii=1:nconditions
            design_inf{2,ii+1} = [onsets{ii}' durations{ii}'];
        end
        save(outfile,'design_inf');
    case 2 % SPM-FNIRS
        outfile = spm_input('Output file name? ','+1','s','');
        [null,~] = spm_input(outfile,'+1','d!','Saving file to disk');
        save(outfile,'names','onsets','durations');
end
