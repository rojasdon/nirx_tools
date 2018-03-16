% This script performs 1st level design specification, statistical
% estimation and contrast steps for a group of subjects with data in
% individual directories.

% you can loop this over many subjects, but should make sure each has
% her/his own custom multiple_conditions.mat file. See nirx_condition_gui.m
% for details.

clear;
basedir = pwd;

% defaults
SPM = [];
o2type = 'HbO'; % estimate this (HbO, HbR, HbT)
nirs_file_filt = '^NIRS.mat$'; % regular expression for file
SPM.xBF.UNITS = 'secs';
conditions_filt = '^multiple_conditions_instructions.mat$';

% directories and contrasts
selected_directories = spm_select ([1 inf], 'dir','Select Directory');
contrast_file = spm_select(1,'file','Select .mat file with contrasts');
load(contrast_file);

for ii=1:size(selected_directories,1)
    cd(strtrim(selected_directories(ii,:)));
    spmdir = pwd; % use the current directory for analysis
    
    % create analysis directory if it doesn't exist
    if ~exist(o2type,'dir')
        mkdir(o2type);
    end
    
    % participant filename
    [~,basename,ext]=fileparts(file(1).name);
    participant_id=spmdir(end-2:end);
    fprintf('Working on %s\n',participant_id);
    file = fullfile(cwd,basename);

    % re-read header
    hdr = nirx_read_hdr([basename '_dsel_odel_gint.hdr']);
    
    % get NIRS.mat file
    nirs_file = spm_select('FPList', pwd, nirs_file_filt);
    
    % load conditions from file
    conditions_file = spm_select('FPList', pwd, conditions_filt);
    load(conditions_file);
    for cond = 1:size(names, 2)
        U(cond).name = names(1,cond);
        U(cond).ons = onsets{1,cond}(:);
        U(cond).dur = durations{1,cond}(:);
    end
    for cond = 1:numel(U)
        U(cond).P.name = 'none';
        U(cond).P.h = 0;
    end
    SPM.Sess.U = U;
    
    % temporal processing, re-applied
    if strcmpi(motion_method,'MARA')
        K.M.type = 'MARA'; 
    else
        K.M.type = 'no'; 
    end
    K.C.type = 'Band-stop filter';
    K.C.cutoff = [0.1200    0.3500;
                  0.7000    1.5000];
    K.D.type = 'yes';
    K.D.nfs = 1;
    K.H.type = 'DCT';
    K.H.cutoff = 128;
    K.L.type = 'HRF';
    P.K = K;
    
    % apply temporal processing
    y = spm_vec(rmfield(Y, 'od')); 
    y = reshape(y, [P.ns P.nch 3]); 
    [fy, P] = spm_fnirs_preproc(y, P);
    
    % could do display of pre-post here using 
    %mask = ones(1, P.nch);
    %mask = mask .* P.mask;
    %ch_roi = find(mask ~= 0);
    % spm_fnirs_viewer_timeseries(y, P, fy, ch_roi);
    
    % save NIRS.mat file
    fprintf('Save NIRS.mat... \n'); 
    P.fname.nirs = fullfile(pwd, 'NIRS.mat');
    save(P.fname.nirs, 'Y', 'P', spm_get_defaults('mat.format')); 
    fprintf('Completed. \n');
    
    % Create file showing number of bad channels for each dataset
    cd(basedir);
    fprintf(fp,'ID=%s,%d\n',participant_id,length(find(ch_stats.allgains>7)));
    fprintf('There are %d bad channels in %s\n',length(find(ch_stats.allgains>7)),basename);
    fclose(fp);
end
