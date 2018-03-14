% This script does the NIRx to NIRS.mat conversion and temporal
% preprocessing steps. It will also delete bad optodes based ones you wish
% to delete for the entire group of subjects processed.

% you can loop this over many subjects, but should make sure each has
% her/his own ch_config.txt and optode_positions.csv in their directories

clear;
basedir = pwd;

% Defaults: this script deletes bad optodes listed below
selected_directories = spm_select ([1 inf], 'dir','Select Directory');
bad_sources = [19,48];
bad_detectors = [];
threshold = 7; % bad gain
distances = [25 60]; % "good" S-D distances
motion_method = 'MARA';
doica = 0;

% summary file for bad channels
fp=fopen('bad_channels.txt','a');

for ii=1:size(selected_directories,1)
    cd(strtrim(selected_directories(ii,:)));
    file=dir('*.evt');
    cwd = pwd;
    [~,basename,ext]=fileparts(file(1).name);
    participant_id=cwd(end-2:end);
    fprintf('Working on %s\n',participant_id);
    file = fullfile(cwd,basename);

    % determine good channels based on distance
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
    [~,~,ch_stats]=nirx_chan_dist([file '_dsel_odel'],distances,'mask','no');
    save([file '_ch_stats'],'ch_stats');

    % interpolate channels based on bad gains
    nirx_interpolate_chans([file '_dsel_odel'],'optode_positions.csv',...
        'threshold',threshold);
    
    % re-read header
    hdr = nirx_read_hdr([basename '_dsel_odel_gint.hdr']);
    
    % convert dataset to NIRS.mat
    fprintf('Converting to NIRS.mat format...\n');
    F = [spm_select('FPList', pwd, ['^' [basename '_dsel_odel_gint'] '.*\' 'wl1' '$']);...
         spm_select('FPList', pwd, ['^' [basename '_dsel_odel_gint'] '.*\' 'wl2' '$']);...
         spm_select('FPList', pwd, ['^' [basename '_dsel_odel_gint'] '.*\' 'hdr' '$'])];
    [y,P] = spm_fnirs_read_nirscout(F);
    fprintf('Completed. \n');
    
    % WATCH OUT: spm_fnirs_read_nirscout produces its own ch_config.txt
    % file. Probably not compatible with the optode deletions, so prob
    % save data from step prior and overwrite it here.
    nirx_write_hdr([basename '_dsel_odel_gint.hdr'],hdr);
    
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
    fprintf('Completed. \n');
    fprintf('Calculate hemoglobin concentration changes...\n');
    [Y.hbo, Y.hbr, Y.hbt] = spm_fnirs_calc_hb(Y, P);
    fprintf('Completed. \n');
    
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
