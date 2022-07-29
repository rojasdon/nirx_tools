% spm12-based GUI input script to edit multiple conditions files

% Author: Don Rojas, Ph.D.

clear;

% defaults
evtfile = '*.evt';

% prompt for participant directories to be analyzed
selected_directories = spm_select([1, inf],'dir','Select Particpant Directories');
pth = pwd;

% now loop through the rest of participants
for ii=1:size(selected_directories,1)
    cd(strtrim(selected_directories(ii,:)));
    pth=pwd;
    
    % subject id
    [~,id,~] = fileparts(pth);
    
    % load evt file
    files = dir(evtfile);
    [onsets,vals]=nirx_read_evt(files(1).name);
    
    if length(onsets) < 25
        fprintf('Name: %s\tNumber: %d\n',files(1).name,length(onsets));
    end
end