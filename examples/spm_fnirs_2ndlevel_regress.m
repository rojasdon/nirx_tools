% runs second level stats on spm_fnirs first-level output. Need a root
% directory for all the contrast images, then will be prompted to input
% various subject 1st level contrast results and an output directory.
% Output is not SPM readable.

% This version runs a multiple linear regression. You need a csv text file of
% regressors of the following form: nrows x ncols
% nrows = number of subjects in your analysis
% ncols = number of additional regressors (within statistical sanity, unlimited)
% the actual number of IV regressors in the model will equal ncols + 1,
% because you are selecting a contrast file that will actually be the first
% regressor, which actually will be the intercept in the overall model. 
% The csv file should not have column and row headers and
% variables should be entered in the same order as the contrast files would
% be selected (e.g., alphanumeric).

% A typical application of this script would be to examine the influence of
% one factor controlling for the effects of other covariates. The beta
% value for the contrast file will be tested for significance controlling for all
% other covariates entered. In essence, this script re-produces the effect
% in SPM models of entering "nuisance" covariates.

clear all;

% DEFAULTS THAT CAN/SHOULD BE CHANGED
model_dir = 'HbO'; % directory within subject directory for files
nchan = 134; % could read this from file, but I'm lazy
pcrit = .05; % uncorrected pval threshold
mc_correct = 1; % apply FDR correction for multiple comparisons, 0 = do not apply

% GET SPM DIRECTORY FOR SURFACES
spmdir = fullfile(spm('dir'),'canonical');

% SELECT PRESENT WORKING DIRECTORY AND SUBJECT DIRECTORIES
cwd             = spm_select(1,'dir','Select root directory for studies',...
                  '',pwd);
cd(cwd);
pth_subjdirs    = spm_select([1,Inf],'dir','Select subject directories to process',...
                  '',pwd);
covs            = spm_select(1,'any','Select a file with regressors/covariates',...
                  '',pth_subjdirs);
firstdir        = fullfile(deblank(pth_subjdirs(1,:)),model_dir);
contrast_name   = spm_select(1,'mat','Select a contrast file to examine',...
                  '',firstdir,'^con.*');
              
[pth,contrast_name,ext] = fileparts(contrast_name);
contrast_name = [contrast_name ext];

% DISPLAY AND STARTING PARAMETERS
nsub = size(pth_subjdirs,1);
fprintf('The following %d subject(s) will be preprocessed:\n',nsub);
disp(pth_subjdirs);

% CREATE SOME DATA AND STATS ARRAYS
cbeta_arr = zeros(nsub,nchan);
pvals = zeros(1,nchan);
tvals = pvals;

% LOOP TO READ DATA
for subj=1:nsub
    confile = fullfile(deblank(pth_subjdirs(subj,:)),model_dir,contrast_name);
    load(confile);
    cbeta_arr(subj,:) = S.cbeta;
end

% READ THE COVARIATES
C = csvread(covs);

% MULTIPLE REGRESSION MODEL
for chan=1:nchan
    % create regression matrix X for chan
    X = [ones(nsub,1) C]; % first column is constant
    Y = cbeta_arr(:,chan);
    [b,~,~,t,p]=multregr(X,Y);
    tvals(chan) = t(1); % intercept t
    pvals(chan) = p(1); % intercept p
end

% PLOT A BRAIN
figure('color','w');
cortex = gifti(fullfile(spmdir,'cortex_8196.surf.gii'));
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'facecolor',[.5,.5,.5],'edgecolor','none');
axis image off;
rotate3d on;
lighting gouraud;
camlight('left');
camlight('right');
hold on;

% PLOT RESULTS, CREATING ANOTHER PATCH FROM 3D SENSOR LOCS
coords = S.ch.xyzC;
loc2d  = double(thetaphi(coords));
tri    = delaunay(loc2d(1,:),loc2d(2,:));
h      = patch('faces',tri,'vertices',coords','edgecolor','none',...
         'facelighting','none','facecolor','interp','facevertexcdata',tvals',...
         'Marker','o','MarkerSize',10,'MarkerEdgeColor',[0 0 0]);
alpha(h,.4); % make semi-transparent
if mc_correct
    pcorr = FDR(pvals,.05);
    if ~isempty(pcorr)
        pcrit = pcorr;
    else
        warning('No values survive multiple comparison correction! Using uncorrected values.');
    end
end
ind = find(pvals < pcrit);
scatter3(coords(1,ind),coords(2,ind),coords(3,ind),40,'r','*');

% SIGNIFICANT CHANNEL LIST
fprintf('Significant channels:\n');
for ii=1:length(ind)
    fprintf('%d:\t%.2f\t%.4f\n',S.ch.label(ind(ii)),tvals(ind(ii)),pvals(ind(ii)));
end

% T-VALS, P-VALS and MASKED T to file
mvals = zeros(1,length(tvals));
mvals(ind) = tvals(ind);
[~,nam,ext] = fileparts(contrast_name);
save(fullfile(cwd,[nam '_tvals.mat']),'tvals','mvals','pvals');


