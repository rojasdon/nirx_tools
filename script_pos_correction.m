% This script corrects the NIRS.mat files to include a reference to a
% standard POS.mat file. Using a standard POS.mat file for all participants
% allows the user to run the spatial processing only once.
% After running spatial processsing, POS.mat should be placed in home dir

% Matt Mathison

clear;

pos_file  = spm_select (1, 'mat','Select Common POS File',{},pwd,'^POS.mat$');
selected_directories    = spm_select ([1 inf], 'dir','Select Participant Directories');

for ii=1:size(selected_directories,1)
    cd(strtrim(selected_directories(ii,:)));
    pth = pwd;
    [~,id,~] = fileparts(pth);
    fprintf('Working on %s\n',id);
    load('NIRS.mat');
    P.fname.pos = pos_file; 
    save('NIRS.mat','P','Y');
end
