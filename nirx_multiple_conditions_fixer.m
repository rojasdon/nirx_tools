% spm12-based GUI input script to edit multiple conditions files

% Author: Don Rojas, Ph.D.

clear;

% defaults
outfile = 'multiple_conditions.mat';
cfile = outfile;

% prompt for participant directories to be analyzed
selected_directories = spm_select([1, inf],'dir','Select Particpant Directories');
pth = pwd;

% should get first participant from list of selected
first_file = selected_directories(1,:);
[pth,participant_id,~] = fileparts(first_file);

% now loop through the rest of participants
for ii=1:size(selected_directories,1)
    cd(strtrim(selected_directories(ii,:)));
    pth=pwd;
    
    % subject id
    [~,id,~] = fileparts(pth);
    
    % reload conditions file
    load(cfile);
    
    % delete the extra onset cell
    onsets(5) = [];

    % save output file
    save(outfile,'names','onsets','durations');
    fprintf('Done\n');
end
fprintf('Finished with all subjects\n');