% Script to move NIRS files out of nested folders
% Summary document is produced each run describing the results
% Author: Matt Mathison, B.S.

clear;

% prompt for directory containing all data
data_directory             = spm_select([1], 'dir','Select Data Directory'); 
cd(data_directory);

% create summary file name (prevents overwrite of previous summary files)
summary_listing            = dir('*.txt');
summary_version            = size(summary_listing,1);
summary_filename           = sprintf('File_Move_Summary%d.txt', summary_version);

% prompt for participant directories to be analyzed
participant_directories    = spm_select([1, inf],'dir','Select Particpant Directories');

% loop script through participant directories
for ii=1:size(participant_directories,1);
    cd(strtrim(participant_directories(ii,:))); % navigate to directory of single participant
    pth                 = pwd;
    listing             = dir(pth);
    folder_contents     = size(listing,1);
    participant_number  = pth(end-2:end);
    
    if folder_contents > 2      % check to see if folder is empty
        
        if folder_contents > 3      % check to see that folder has no unexpected files
            warning('Unexpected files in directory for Participant %s', participant_number);
            results = "Unexpected Files";
            
        else                                    % folder is not empty and has no unexpected files
            file            = dir('**/*.evt');  % find NIRX files
            tf_file_found   = isempty(file);    % T/F .evt file was found?
            
            if tf_file_found == 0                   % file was found
                nested_folder   = file.folder;      % tag folder containing NIRX files
                cd(nested_folder);                  % move to folder containing NIRX files
                movefile NIRS* ../..;               % move NIRX files up two directories
                results = "Success!";
                
            else        % file was not found
               warning('File not found for Participant %s', participant_number); 
               results = "NIRS file not found";
            end
        end
        
    else            % folder does not contain NIRX files or directories
       warning('There are no files for Participant %s', participant_number);
       results = "No files found";
    end
    
     % Create file displaying results of script
    cd(data_directory);
    fp=fopen(summary_filename,'a');
    fprintf(fp,'ID=%s:',participant_number);
    fprintf(fp,'%s \n',results);
    fclose('all');
end
cd(data_directory);

