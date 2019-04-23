% runs second level stats on spm_fnirs first-level output. Need a root
% directory for all the contrast images, then will be prompted to input
% various subject 1st level contrast results and an output directory.
% Output is not SPM readable.

% This script is for ROI output (see script_regions_of_interest.m)

clear;

% DEFAULTS THAT CAN BE CHANGED
model_dir = 'HbO_ROI'; % directory within subject directory for files
nroi = 9; % could read this from file, but I'm lazy
pcrit = .05; % uncorrected pval threshold
mc_correct = 1; % apply FDR correction for multiple comparisons, 0 = do not apply

% SELECT PRESENT WORKING DIRECTORY AND SUBJECT DIRECTORIES
cwd             = spm_select(1,'dir','Select root directory for studies',...
                  '',pwd);
cd(cwd);
pth_subjdirs    = spm_select([1,Inf],'dir','Select subject directories to process',...
                  '',pwd);
firstdir        = fullfile(deblank(pth_subjdirs(1,:)),model_dir);
contrast_name   = spm_select(1,'mat','Select a contrast file to examine',...
                  '',firstdir,'^con.*');
roi_names       = spm_select(1,'txt','Select a file with ROI names','',cwd,'^ch_config.*');
              
[pth,contrast_name,ext] = fileparts(contrast_name);
contrast_name = [contrast_name ext];

% READ ROI DATA
roidata = readtable(roi_names);
roi_names = unique(roidata.ROI);

% DISPLAY AND STARTING PARAMETERS
nsub = size(pth_subjdirs,1);
fprintf('The following %d subject(s) will be preprocessed:\n',nsub);
disp(pth_subjdirs);

% CREATE SOME DATA AND STATS ARRAYS
cbeta_arr = zeros(nsub,nroi);
pvals = zeros(1,nroi);
tvals = pvals;

% LOOP TO READ DATA
for subj=1:nsub
    confile = fullfile(deblank(pth_subjdirs(subj,:)),model_dir,contrast_name);
    load(confile);
    cbeta_arr(subj,:) = S.cbeta;
end

% ONE-SAMPLE T-TEST OVER CHANNELS
for roi=1:nroi
    [~,pvals(roi),~,stats]=ttest(cbeta_arr(:,roi));
    tvals(roi) = stats.tstat;
end

% multiple comparison correction?
if mc_correct
    pcorr = FDR(pvals,.05);
    if ~isempty(pcorr)
        pcrit = pcorr;
    else
        warning('No values survive multiple comparison correction! Using uncorrected values.');
    end
end
ind = find(pvals < pcrit);

% SIGNIFICANT ROI LIST
if ~isempty(ind)
    fprintf('Significant Regions:\n');
    for ii=1:length(ind)
        fprintf('%s:\t%.2f\t%.4f\n',roi_names{ind(ii)},tvals(ind(ii)),pvals(ind(ii)));
    end
else
    fprintf('No values survived uncorrected p < %s!\n',num2str(pcrit));
end


