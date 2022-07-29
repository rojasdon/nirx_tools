% This script takes output from script_temporal_processing.m and applies a
% region of interest approach rather than a whole brain statistical model

% you can loop this over many subjects, but should make sure each has
% her/his own ch_config.txt and optode_positions.csv in their directories.

% A file should be supplied in the expanded form of a ch_config.txt file
% specifying what channels belong to each ROI as follows:
% Ch, Source, Detector,ROI
% 38,13,5,SMA
% 
% where the line under the header indicates channel 38, consisting of
% source 13 and detector 5, belongs to a region called SMA

% Author: Don Rojas, Ph.D.
% Version history: first working version 03/20/2019

clear;

% defaults
roi_file = 'ch_config_ROI_10-10.txt';
combination_method = 'avg'; % 'avg' for average | 'pca' for 1st principle component
spmdir = 'HbO'; % subdirectory with first level results
outdir = [spmdir '_ROI'];
spmfile = 'SPM.mat';
nirsfile = 'NIRS.mat';
con_prefix = 'con_';

% directories and files
basedir = spm_select(1,'dir','Select base directory');
selected_directories = spm_select ([1 inf], 'dir','Select Directories',{},basedir);
contrast_file = spm_select(1,'mat','Select .mat file with contrasts',{},basedir,'.mat$');
load(contrast_file); % should have 2 fields, name and contrast
roidata = readtable(roi_file);

% main loop
for ii=1:size(selected_directories,1)
    % navigate to subject directory
    cd(strtrim(selected_directories(ii,:)));
    cwd = pwd;
    participant_id=cwd(end-2:end);
    fprintf('Working on %s\n',participant_id);
    
    % create output directory if needed
    if ~exist(fullfile(cwd,outdir),'dir')
        mkdir(fullfile(cwd,outdir));
    end
    
    % load files
    load(nirsfile);
    load(fullfile(pwd,spmdir,spmfile));
    
    % temporal processing - not saved in NIRS.mat file
    y = spm_vec(rmfield(Y, 'od')); 
    y = reshape(y, [P.ns P.nch 3]); 
    P.fname.nirs = fullfile(pwd, 'NIRS.mat');
    [fy, P] = spm_fnirs_preproc(y, P);
    fy = spm_fnirs_filter(fy, P, P.K.D.nfs); % DCT filter
    
    % clear some data
    clear roi_data dv;
    
    % get rois names, channels and data
    roi_names = unique(roidata.ROI);
    for roi=1:length(roi_names)
        roi_ind{roi} = find(ismember(roidata.ROI,roi_names{roi}));
        roi_data{roi} = squeeze(fy(:,roi_ind{roi},1)); % hardcoded to HbO - need to change if HbR or HbT
    end
    
    % apply reduction to ROI
    switch combination_method
        case 'avg'
            for roi=1:length(roi_names)
                dv(roi,:) = mean(roi_data{roi},2);
            end
        case 'pca'
            for roi=1:length(roi_names)
                [wcoeff,score,~,~,explained(roi)] = pca(roi_data{roi},'variableweights','variance');
                dv(roi,:) = score(:,1)'; % first principle component
            end
    end
    
    % get design matrix from SPM
    M = SPM.xX.X; % this field is design matrix, convolved with HRF
    % M = SPM.xX.xKXs.X; % this is same as xx.X, but with LPF and whitening, if applied
    
    % regression for each roi
    for roi=1:length(roi_names)
        [b(roi,:),~,~,~,~]=multregr(M,dv(roi,:)');
    end
    
    % apply contrasts (sum of weights * betas) nroi x ncon array
    for roi=1:length(roi_names)
        for con=1:size(contrast,1)
            roi_con(roi,con) = sum(contrast(con,:) .* b(roi,:));
        end
    end
            
    % save the contrast estimate files in the form con_0001.mat,
    % con_0002.mat, etc. in S.cbeta format 1 x nROI array
    for con=1:size(contrast,1)
        num = num2str(con);
        switch length(num)
            case 1
                num = ['000' num];
            case 2
                num = ['00' num];
        end
        savename = [con_prefix num '.mat'];
        S.cbeta = roi_con(:,con)';
        save(fullfile(cwd,outdir,savename),'S');
    end

end
fprintf('Finished with all subjects\n');
