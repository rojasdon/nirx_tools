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
ar1 = 'no'; % autocorrelations correction? yes|no

% directories and contrasts
base_dir = spm_select(1,'dir','Select a home directory');
selected_directories = spm_select ([1 inf], 'dir','Select subject directories',{},base_dir);
contrast_file = spm_select(1,'mat','Select .mat file with contrasts',{},base_dir,'.mat$');
load(contrast_file);

for ii=1:size(selected_directories,1)
    cd(strtrim(selected_directories(ii,:)));
    spmdir = pwd; % use the current directory for analysis
    
    % create analysis directory if it doesn't exist
    if ~exist(o2type,'dir')
        mkdir(o2type);
    end
    
    % get NIRS.mat file and subject id
    nirs_file = spm_select('FPList', pwd, nirs_file_filt);
    [~,basename,ext]=fileparts(nirs_file);
    participant_id=spmdir(end-2:end); % may need to be more forgiving
    fprintf('Working on %s\n',participant_id);
    load(nirs_file);
    
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
    
    % resampling?
    switch P.K.D.type
        case 'yes'
            fs = P.K.D.nfs;
            ns = P.K.D.ns;
        case 'no'
            fs = P.fs;
            ns = P.ns;
    end

    SPM.xY.RT = 1/fs;
    SPM.nscan = ns;
    
    % TR stuff for hrf
    try
        SPM.xBF.T  = spm_get_defaults('stats.fmri.t');
    catch
        SPM.xBF.T  = 16;
    end

    try
        SPM.xBF.T0 = spm_get_defaults('stats.fmri.t0');
    catch
        SPM.xBF.T0 = 8;
    end
    SPM.xBF.dt = SPM.xY.RT/SPM.xBF.T;
    SPM.xBF.Volterra = 1; % 1st Volterra expansion
    SPM.Sess.U = spm_get_ons(SPM,1);
    
    % AR(1), if requested
    switch ar1
        case 'no'
            SPM.xVi.V  = speye(sum(ns));
            ar1 = 'i.i.d';
        case 'yes'  % assume AR(0.2) in xVi.Vi
            SPM.xVi.Vi = spm_Ce(ns,0.2);
            ar1 = 'AR(0.2)';
    end
    SPM.xVi.form = ar1;
    
    %  generate design matrix using specified parameters
    SPM.xY.VY = P.fname.nirs; % file name of Y
    SPM0 = SPM;
    save_SPM = 0;
    fprintf('Generating design matrix for %s...\n', o2type);
    [SPM] = spm_fMRI_design(SPM0, save_SPM);
    SPM.xY.type = o2type; 
    if strcmpi(o2type, 'HbR')
        if strcmpi(SPM.xBF.name, 'hrf') || strcmpi(SPM.xBF.name, 'hrf (with time derivative)') || strcmpi(SPM.xBF.name, 'hrf (with time and dispersion derivatives)')
            SPM.xX.X(:,1:end-1) = SPM.xX.X(:,1:end-1).*(-1);
        end
    end
    fprintf('Completed. \n\n');
    
    % Design spec for reporting/display
    ntr = length(SPM.Sess.U);
    Bstr = sprintf('[%s] %s', o2type, SPM.xBF.name);
    Hstr = sprintf('Cutoff: %d {s}',P.K.H.cutoff);
    Lstr = P.K.L.type;
    if strcmpi(Lstr, 'Gaussian'), Lstr = sprintf('%s, FWHM %d', Lstr, P.K.L.fwhm); end
    SPM.xsDes = struct(...
        'Basis_functions',      Bstr,...
        'Number_of_sessions',   sprintf('%d',1),...
        'Trials_per_session',   sprintf('%-3d',ntr),...
        'Interscan_interval',   sprintf('%0.2f {s}',SPM.xY.RT),...
        'High_pass_Filter',     Hstr,...
        'Low_pass_Filter', Lstr);
    spm_DesRep('DesMtx',SPM.xX,[],SPM.xsDes);
    swd = fullfile(sdir, o2type);
    SPM.swd = swd;
    fprintf('Saving SPM.mat... \n');
    save(fullfile(SPM.swd, 'SPM.mat'), 'SPM', spm_get_defaults('mat.format'));
    fprintf('Completed. \n\n');
    
    tmp = 0;
    if tmp
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
end
