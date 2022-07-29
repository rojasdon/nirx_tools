% script to batch convert nirx files into homer2. Note it may only be
% successful with nirx datasets that have been preprocessed.

% directories and files
file_filter = '*_dsel.hdr';
basedir = spm_select(1,'dir','Select base directory');
cd(basedir);
selected_directories = spm_select ([1 inf], 'dir','Select Directories',{},basedir);
SD_file = spm_select(1,'any','Select probes.SD file with montage',{},basedir,'.SD$');

% loop over subjects
nsub = size(selected_directories,1);
for sub = 1:nsub
    % change directory
    cdir = deblank(selected_directories(sub,:));
    cd(cdir);
    
    % get filename to convert
    file = dir(file_filter);
    [~,base,~] = fileparts(file(1).name);
    
    % convert files
    fprintf('Working on %s...',base);
    nirx2homer2('.',base,SD_file);
    fprintf('done!\n');
    
    % change directory
    cd(basedir);
end
