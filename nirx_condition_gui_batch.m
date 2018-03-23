% spm12-based GUI input script for producing multi-condition event mat file
% for spm_fnirs from nirx .evt file input

% Author: Don Rojas, Ph.D.
% Batch version: Matt Mathison, based on nirx_condition_gui.m
clear;

% prompt for participant directories to be analyzed
selected_directories    = spm_select([1, inf],'dir','Select Particpant Directories');
cd(strtrim(selected_directories(1,:)));
pth             = pwd;
participant_id  = '001';

% button select which version of header file to use
% there's probably a much better way to do this...
hdr_selection = spm_input('Version of header file to use?','','b',{'Original','dsel','d/odel','d/o/gint'},1:4,'');
    if hdr_selection == 1
        header_type = '.hdr';
    end
    if hdr_selection == 2
        header_type = 'dsel.hdr';
    end
    if hdr_selection == 3
        header_type = 'dsel_odel.hdr';
    end
    if hdr_selection == 4
        header_type = 'dsel_odel_gint.hdr';
    end
    full_header_type = strcat('*',participant_id,'_',header_type);
    
% find event file
found_event_file        = dir('*.evt');
event_file              = fullfile(found_event_file.folder,found_event_file.name);

% read event file
[onsetvec, trigvals]    = nirx_read_evt(event_file);
trigs                   = unique(trigvals);
nconditions             = length(trigs);
names                   = cell(1,nconditions);
dur                     = zeros(1,nconditions);

% input is in seconds or scans/samples?
inp_sec_scan = spm_input('Onsets/Durations scaling?','','b',{'Seconds','Scans'},1:2,'');

% scale input to seconds if requested
if inp_sec_scan == 1
    found_hdr   = dir(full_header_type);
    hfile       = fullfile(found_hdr.folder, found_hdr.name);
    hdr         = nirx_read_hdr(hfile);
    sr          = 1/hdr.sr;
    onsetvec    = sr * onsetvec;
end

% report 1st trigger 
spm_input(num2str(onsetvec(1)),'+1','d!','First trigger time');

% get condition names and durations 
for ii = 1:nconditions
    names{ii}       = spm_input(['Condition ' num2str(trigs(ii)) ' name?'],'+1','s','');
    dur(ii)         = str2num(spm_input(['Condition ' num2str(ii) ' duration?'],'+1','s',''));
end

% save unmodified names for loop later
initial_names   = names;
initial_dur     = dur;
n_conditions    = length(names); 

% prompt to add a condition, such as an instruction set, that is coded
% only by the condition trigger, not separately. An example is when a block
% of trials is always preceded by an instruction, but the trigger came on
% the instruction, not the trials. In such cases, an offset of the trigger
% can be accomplished here to more correctly align with the stimuli
inp_add_instr = spm_input('Do you want to add an offset and model an instruction?','','b',{'Yes','No'},1:2,'');
offset = 0;
if inp_add_instr == 1
    offset          = spm_input('Offset in sec or scans:','+1','e');
    origvec         = onsetvec;
    names{end+1}    = 'Instruction';
end
onsetvec = onsetvec + offset;

% onsets
for ii = 1:n_conditions
    tind            = find(trigvals == trigs(ii));
    onsets{ii}      = onsetvec(tind)';
    durations{ii}   = repmat(dur(ii),1,length(onsets{ii}));
end

% add onsets/durations for instruction condition
if inp_add_instr == 1
    onsets{end+1}       = origvec';
    durations{end+1}    = repmat(offset,1,length(origvec));
end
n_conditions = length(names);

% prompt to remove a condition (such as rest) that has a coded trigger
% value - useful for implicit baseline
inp_remove = spm_input('Do you want to delete a condition/trigger?','','b',{'Yes','No'},1:2,'');
if inp_remove == 1
    [sel,ok]        = listdlg('liststring',names,'PromptString','Select Condition(s) to Remove');
    names(sel)      = [];
    onsets(sel)     = [];
    durations(sel)  = [];
end

% save output
outfile     = spm_input('Output file name? ','+1','s','');
[null,~]    = spm_input(outfile,'+1','d!','Saving file to disk');
save(outfile,'names','onsets','durations');


% now loop through the rest of participants
for ii=2:size(selected_directories,1);
    cd(strtrim(selected_directories(ii,:)));
    pth=pwd;
 
    % find event file
    found_event_file        = dir('*.evt');
    event_file              = fullfile(found_event_file.folder,found_event_file.name);

    % read event file
    [onsetvec, trigvals]    = nirx_read_evt(event_file);
    trigs                   = unique(trigvals);
    nconditions             = length(trigs);
    names                   = cell(1,nconditions);
    dur                     = zeros(1,nconditions);

    % scale input to seconds if requested
    if inp_sec_scan == 1
        % find header file using suffix supplied at start of script
        found_hdr   = dir(full_header_type);
        hfile       = fullfile(found_hdr.folder, found_hdr.name);
        hdr         = nirx_read_hdr(hfile);
        sr          = 1/hdr.sr;
        onsetvec    = sr * onsetvec;
    end

    % get unmodified condition names and durations 
    names           = initial_names;
    dur             = initial_dur;
    n_conditions    = length(names); 

    % prompt to add a condition, such as an instruction set, that is coded
    % only by the condition trigger, not separately. An example is when a block
    % of trials is always preceded by an instruction, but the trigger came on
    % the instruction, not the trials. In such cases, an offset of the trigger
    % can be accomplished here to more correctly align with the stimuli
    if inp_add_instr == 1
        origvec         = onsetvec;
        names{end+1}    = 'Instruction';
    end
    onsetvec = onsetvec + offset;

    % onsets
    for ii = 1:n_conditions
        tind            = find(trigvals == trigs(ii));
        onsets{ii}      = onsetvec(tind)';
        durations{ii}   = repmat(dur(ii),1,length(onsets{ii}));
    end
    
    % add onsets/durations for instruction condition
    if inp_add_instr == 1
        onsets{end+1}       = origvec';
        durations{end+1}    = repmat(offset,1,length(origvec));
    end
    n_conditions = length(names);

    % prompt to remove a condition (such as rest) that has a coded trigger
    % value - useful for implicit baseline
    if inp_remove == 1
        names(sel)      = [];
        onsets(sel)     = [];
        durations(sel)  = [];
    end

    % save output
    fprintf('Saving file to disk...');
    save(outfile,'names','onsets','durations');
    fprintf('Done\n');
end
fprintf('Finished with all subjects\n');