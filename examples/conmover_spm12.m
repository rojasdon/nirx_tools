% file to move/rename contrast files for better organization

clear;
basedir         = spm_select(1,'dir','Select home directory',...
                  '',pwd);    
pth_subjdirs    = spm_select([1,Inf],'dir','Select subject directories to process',...
                  '',basedir);         
subjid_chars    = spm_input('# of characters identifying your subjects?',1,'b',...
                    '2|3|4|5|6|7|8|9|10|11',[2 3 4 5 6 7 8 9 10 11], 6); 
model_dir       = spm_select(1,'dir','Select model directory example',...
                    '',pth_subjdirs(1,:)); % model directory containing con* files
[path,file]     = fileparts(model_dir);
modeldirstub    = file; 
dest_dir        = spm_select(1,'dir','Select destination directory','',pwd);  % output directory

nsub = size(pth_subjdirs,1); 
for sub=1:nsub 
    cwd = fullfile(pth_subjdirs(sub,:),modeldirstub); % go to directory with cons 
    cd(cwd);
    len = length(pth_subjdirs(sub,:));
    subject_id = pth_subjdirs(sub,(len-(subjid_chars-1):len)); % change numbers to represent unique subject info ie DD001
    file2copy = dir('con*.*');     %get list of files to copy 
    for ff = 1:numel(file2copy) 
       [p,pre,post]=fileparts(file2copy(ff).name); 
       copyfile(file2copy(ff).name, fullfile(dest_dir, [pre '_' subject_id post]));    %copy just one file 
    end 
end 
