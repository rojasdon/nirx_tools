% spm12-based GUI input script for producing multi-condition event mat file
% for spm_fnirs from nirx .evt file input

% Author: Don Rojas, Ph.D.
% Batch version: Matt Mathison, based on nirx_condition_gui.m
clear;

% defaults
hdr_ext = '.hdr';
evt_ext = '.evt';
outfile = 'multiple_conditions.mat';

% prompt for participant directories to be analyzed
selected_directories = spm_select([1, inf],'dir','Select Particpant Directories');
pth = pwd;

% should get first participant from list of selected
first_file = selected_directories(1,:);
[pth,participant_id,~] = fileparts(first_file);

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
found_event_file        = dir([pth filesep participant_id filesep '*.evt']);
event_file              = fullfile(found_event_file.folder,found_event_file.name);

% prompt for example condition file to use that will have names and
% durations already in it
cfile = spm_select(1,'mat','Select example condition file...');
load(cfile,'names','durations');

% input is in seconds or scans/samples?
inp_sec_scan = spm_input('Onsets/Durations scaling?','','b',{'Seconds','Scans'},1:2,'');

% get condition names and durations 
%for ii = 1:nconditions
 %   names{ii}       = spm_input(['Condition ' num2str(trigs(ii)) ' name?'],'+1','s','');
  %  dur(ii)         = str2num(spm_input(['Condition ' num2str(ii) ' duration?'],'+1','s',''));
%end

% prompt to add a condition, such as an instruction set, that is coded
% only by the condition trigger, not separately. An example is when a block
% of trials is always preceded by an instruction, but the trigger came on
% the instruction, not the trials. In such cases, an offset of the trigger
% can be accomplished here to more correctly align with the stimuli
inp_add_instr = spm_input('Do you want to add an offset and model an instruction?','','b',{'Yes','No'},1:2,'');

% add onsets/durations for instruction condition
if inp_add_instr == 1
    offset = spm_input('Enter an offset in seconds','+0','w1');
end

% now loop through the rest of participants
for ii=1:size(selected_directories,1)
    cd(strtrim(selected_directories(ii,:)));
    pth=pwd;
    
    % subject id
    [~,id,~] = fileparts(pth);
    
    % reload conditions file
    load(cfile,'names','durations');
 
    % find event file
    event_file        = spm_select('FPList',pwd,'.*.evt$');
    if (size(event_file,1) > 1)
        event_file = event_file(1,:);
    end
    
    % read event file
    [onsetvec, trigvals]    = nirx_read_evt(event_file);
    trigs                   = unique(trigvals);
    
    % delete 1 trig if present (Matt's study)
    if find(trigs == 1)
        trigs(trigs == 1) = [];
    end
    nconditions             = length(trigs);

    % scale input to seconds if requested
    if inp_sec_scan == 1
        % find header file using suffix supplied at start of script
        hfile       = spm_select('FPList',pwd,'.*.hdr$');
        % if multiple hdr files, choose shortest name
        if size(hfile,1) > 1
            len = [];
            for file = 1:size(hfile,1)
                len(file) = length(deblank(hfile(file,:)));
            end
            [~,ind] = min(len);
            hfile = deblank(hfile(ind,:));
        end
        hdr         = nirx_read_hdr(hfile);
        sr          = 1/hdr.sr;
        onsetvec    = sr * onsetvec;
    end

    % add a condition, such as an instruction set, that is coded
    % only by the condition trigger, not separately. An example is when a block
    % of trials is always preceded by an instruction, but the trigger came on
    % the instruction, not the trials. In such cases, an offset of the trigger
    % can be accomplished here to more correctly align with the stimuli
    if inp_add_instr == 1
        origvec         = onsetvec;
        %names{end+1}    = 'Instruction';
        onsetvec = onsetvec + offset;
    else
        onsetvec = onsetvec;
    end

    % onsets
    for ons = 1:nconditions
        tind            = find(trigvals == trigs(ons));
        onsets{ons}      = onsetvec(tind)';
    end
    
    % add onsets/durations for instruction condition
    if inp_add_instr == 1
        onsets{end}       = origvec';
        durations{end}    = repmat(offset,1,length(origvec));
    end
    
    % hard coding durations loop
    %for dur = 1:nconditions
    %    durations{dur} = durations{dur} - 2;
    %end

    % save output file
    fprintf('Saving file to disk...');
    save(outfile,'names','onsets','durations');
    fprintf('Done\n');
    clearvars -except ii hdr_ext evt_ext outfile selected_directories pth cfile ...
        inp_sec_scan inp_add_instr offset;
end
fprintf('Finished with all subjects\n');