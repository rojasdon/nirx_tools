% This script does the NIRx to NIRS.mat conversion and temporal
% preprocessing steps. It will also delete bad optodes based ones you wish
% to delete for the entire group of subjects processed.

% you can loop this over many subjects, but should make sure each has
% her/his own ch_config.txt and optode_positions.csv in their directories

% Authors: Don Rojas, Ph.D.
%          Matt Mathison
% Version history: first working version 03/22/2018

clear;

% Defaults: this script deletes bad optodes listed below
bad_sources = [1,19,20,48];
bad_detectors = [];
threshold = 7; % bad gain
distances = [20 50]; % "good" S-D distances
motion_method = 'MARA';
filterdata = 0;
doica = 0;


% directories and files
basedir = spm_select(1,'dir','Select base directory');
selected_directories = spm_select ([1 inf], 'dir','Select Directories',{},basedir);
configfile = spm_select(1,'any','Select ch_config.txt file...',{},basedir,'^ch_config.txt$');
posfile = spm_select(1,'any','Select optode_positions.csv file...',{},basedir,'^optode_positions.csv$');

% summary file for bad channels
fp=fopen('bad_channels.txt','a');

for ii=1:size(selected_directories,1)
    cd(strtrim(selected_directories(ii,:)));
    % delete existing optode files
    if exist('optode_positions.csv','file')
        delete('optode_positions.csv');
    end
    if exist('ch_config.txt','file')
        delete('ch_config.txt');
    end
    file=dir('*.evt');
    cwd = pwd;
    [~,basename,ext]=fileparts(file(1).name);
    participant_id=cwd(end-2:end);
    fprintf('Working on %s\n',participant_id);
    file = fullfile(cwd,basename);
    
    % determine if ch_config and optode_positions present
    copyfile(configfile,fullfile(pwd,'ch_config.txt'));
    copyfile(posfile,fullfile(pwd,'optode_positions.csv'));
    
    % distance criteria applied
    [~,~,~]=nirx_chan_dist(file,distances,'all','yes');
    
    % find the bad channels formed by bad sources/detectors
    hdr = nirx_read_hdr([file '_dsel.hdr']);
    sind = [];
    dind = [];
    for ii=1:length(bad_sources)
        sind = [sind; find(hdr.SDpairs(:,1) == bad_sources(ii))];
    end
    for ii=1:length(bad_detectors)
        dind = [dind; find(hdr.SDpairs(:,2) == bad_detectors(ii))];
    end
    bind = unique([sind; dind]);

    % delete bad optodes
    nirx_delete_optodes([file '_dsel'],bad_sources,bad_detectors,'correct');
    
    % redo distance selection, without re-write, based on the channel mask
    [~,~,ch_stats]=nirx_chan_dist([file '_dsel_odel'],distances,'mask','no');
    save([file '_ch_stats'],'ch_stats');

    % interpolate channels with bad gains
    nirx_interpolate_chans([file '_dsel_odel'],'optode_positions.csv',...
        'threshold',threshold);
    
    % re-read header for below - see nirx_write_ch_config line
    hdr = nirx_read_hdr([basename '_dsel_odel_gint.hdr']);
    
    % convert dataset to NIRS.mat
    fprintf('Converting to NIRS.mat format...\n');
    F = [spm_select('FPList', pwd, ['^' [basename '_dsel_odel_gint'] '.*\' 'wl1' '$']);...
         spm_select('FPList', pwd, ['^' [basename '_dsel_odel_gint'] '.*\' 'wl2' '$']);...
         spm_select('FPList', pwd, ['^' [basename '_dsel_odel_gint'] '.*\' 'hdr' '$'])];
    [y,P] = spm_fnirs_read_nirscout(F);
    fprintf('Completed. \n');
    
    % spm_fnirs_read_nirscout produces its own ch_config.txt
    % file. Probably not compatible with the optode deletions, so overwrite
    % it here with saved header
    nirx_write_ch_config('ch_config.txt',hdr);
    
    % apply Beer-Lambert Law "Convert Button" step in spm_fnirs - see
    % spm_fnirs_convert_ui.m
    P.wave = hdr.wl;
    P.d = ch_stats.dist;
    P.acoef = [1.4033    3.8547;
               2.6694    1.8096];
    P.dpf = [6.0022 4.9399];
    P.base = [1 P.ns];
    fprintf('Calculate optical density changes...\n'); 
    [Y.od, P] = spm_fnirs_calc_od(y, P);
    fprintf('Completed.\n');
    fprintf('Calculate hemoglobin concentration changes...\n');
    [Y.hbo, Y.hbr, Y.hbt] = spm_fnirs_calc_hb(Y, P);
    fprintf('Completed.\n');
    
    % ICA/PCA - not ready to use yet
    if doica
        data = Y.hbo';
        [U,W,compsig,cum_var] = nirx_ica(data,'method','pca','lasteig',P.nch);
        [~,cind] = min(abs(round(cum_var) - 97));
        nsig = size(compsig,1);
        if strcmpi(motion_method,'ica')
            weights = W;
        else
            weights = pinv(U);
        end
        remove = 1:(nsig-cind+1);
        tra        = eye(P.nch);
        tokeep     = setdiff(1:size(weights,1),remove);
        tmpdata    = (weights(tokeep,:) * tra) * data;
        newhbo     = U(:,tokeep) * tmpdata;
        Y.hbo      = newhbo';
        % should correct the hbr and hbt as well
    end
    
    % temporal processing options
    if strcmpi(motion_method,'MARA')
        K.M.type = 'MARA';
        K.M.chs = 1:P.nch;
        K.M.L = 1;
        K.M.th = 3;
        K.M.alpha = 5;
    else
        K.M.type = 'no'; 
    end
    if filterdata 
        K.C.type = 'Band-stop filter';
        K.C.cutoff = [0.1200    0.3500;
                      0.7000    1.5000];
    else
        K.C.type = 'no';
    end
    K.D.type = 'no';
    K.D.nfs = hdr.sr;
    K.H.type = 'DCT';
    K.H.cutoff = 128;
    K.L.type = 'HRF';
    P.K = K;
    
    % save motion parameter file
    chs = 1:P.nch;
    L = K.M.L;
    th = K.M.th;
    alpha = K.M.alpha;
    save('motion_params.mat','chs','L','alpha','th');
    
    % apply temporal processing
    y = spm_vec(rmfield(Y, 'od')); 
    y = reshape(y, [P.ns P.nch 3]); 
    P.fname.nirs = fullfile(pwd, 'NIRS.mat');
    [fy, P] = spm_fnirs_preproc(y, P);
    
    % DCT filter not strictly necessary, because this filter is applied during estimation, but ...
    % if you want to view results as in GUI should leave it here
    fy = spm_fnirs_filter(fy, P, P.K.D.nfs); 
    
    % could do display of pre-post here using 
    %mask = ones(1, P.nch);
    %mask = mask .* P.mask;
    %ch_roi = find(mask ~= 0);
    % spm_fnirs_viewer_timeseries(y, P, fy, ch_roi);
    
    % save NIRS.mat file
    fprintf('Save NIRS.mat... \n'); 
    save(P.fname.nirs, 'Y', 'P', spm_get_defaults('mat.format')); 
    fprintf('Completed. \n');
    
    % Create file showing number of bad channels for each dataset
    cd(basedir);
    fprintf(fp,'ID=%s,%d\n',participant_id,length(find(ch_stats.allgains>7)));
    fprintf('There are %d bad gain channels in %s\n',length(find(ch_stats.allgains>7)),basename);
end
fclose(fp);
fprintf('Finished with all subjects\n');
