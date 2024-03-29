% runs second level stats on spm_fnirs first-level output. Need a root
% directory for all the contrast images, then will be prompted to input
% files for each group. It will then loop through all
% contrasts of similar name and collect data for stats.

clear all;

% DEFAULTS THAT CAN BE CHANGED
model_dir = 'HbO'; % directory within subject directory for files
nchan = 103; % could read this from file, but I'm lazy
pcrit = .05; % uncorrected pval threshold
variancetype = 1; % 1 for equal, 2 for unequal
mc_correct = 1; % apply FDR correction for multiple comparisons, 0 = do not apply
mc_type = 'holm'; % 'fdr', 'bonferroni' or 'holm'
roi_chans = [72 73 74 76 77 78 79 80 ...
             81 82 83 91 93 94 99 100 ...
             101 103];
roi = 0; % 0 for whole brain

         
% GET SPM DIRECTORY FOR SURFACES
spmdir = fullfile(spm('dir'),'canonical');

% SELECT PRESENT WORKING DIRECTORY AND SUBJECT DIRECTORIES
cwd             = spm_select(1,'dir','Select root directory for studies',...
                  '',pwd);
cd(cwd);

% SELECT FILES
g1files = spm_select(Inf,'mat','Select group 1 files',...
                  '',cwd,'_con_.*');
g2files = spm_select(Inf,'mat','Select group 2 files',...
                  '',cwd,'_con_.*');
g1n = size(g1files,1);
g2n = size(g2files,1);

% LIMIT TO ROI?
cind = 1:nchan;
if roi
    nchan = length(roi_chans);
	todelete = setdiff(cind,roi_chans);
else
    todelete = [];
end

% CREATE SOME DATA AND STATS ARRAYS
g1_arr = zeros(g1n,nchan);
g1_roi = zeros(g1n,1);
g2_arr = zeros(g2n,nchan);
pvals = zeros(1,nchan);
g2_roi = zeros(g2n,1);
tvals = pvals;

% LOOP TO READ DATA INTO ARRAYS
for subj=1:g1n
    load(g1files(subj,:));
    tmp = S.cbeta;
    tmp(todelete) = [];
    g1_roi(subj) = mean(tmp);
    g1_arr(subj,:) = tmp;
end

for subj=1:g2n
    load(g2files(subj,:));
    tmp = S.cbeta;
    tmp(todelete) = [];
    g1_roi(subj) = mean(tmp);
    g2_arr(subj,:) = tmp;
end

% LOOP T-TEST OVER CHANS
for chan=1:nchan
    [tvals(chan), pvals(chan)] = t_test(g1_arr(:,chan), g2_arr(:,chan),...
        variancetype,2);
end

% T-TEST ON MEAN ROI
[t, p] = t_test(g1_roi, g2_roi,variancetype,2);

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
if roi
    coords(:,todelete) = [];
end
loc2d  = double(thetaphi(coords));
tri    = delaunay(loc2d(1,:),loc2d(2,:));
h      = patch('faces',tri,'vertices',coords','edgecolor','none',...
         'facelighting','none','facecolor','interp','facevertexcdata',tvals',...
         'Marker','o','MarkerSize',10,'MarkerEdgeColor',[0 0 0]);
alpha(h,.4); % make semi-transparent

% MULTIPLE COMPARISON CORRECTION?
if mc_correct
    switch mc_type
        case 'fdr'
            pcorr = FDR(pvals,pcrit);
        case 'bonferroni'
            pcorr = pcrit/nchan;
        case 'holm'
            pcorr = holm_bonferroni(pvals,pcrit);
    end   
end

if isempty(pcorr)
    warning('No values survive correction. Plotting uncorrected result!');
    ind = find(pvals < pcrit);
else
    ind = find(pvals < pcorr);
    if isempty(ind)
        warning('No values survive correction. Plotting uncorrected result!');
        ind = find(pvals < pcrit);
    end
end
scatter3(coords(1,ind),coords(2,ind),coords(3,ind),40,'r','*');

% SIGNIFICANT CHANNEL LIST
fprintf('Significant channels:\n');
for ii=1:length(ind)
    fprintf('%d:\t%.2f\t%.2f\n',S.ch.label(ind(ii)),tvals(ind(ii)),pvals(ind(ii)));
end

% PRINT MEAN ROI RESULT
fprintf('Group 1 Mean: %.3f +/- %.3f\n',mean(g1_roi),std(g1_roi));
fprintf('Group 2 Mean: %.3f +/- %.3f\n',mean(g2_roi),std(g2_roi));
fprintf('Mean ROI T: %.3f\tP: %.3f\n',t,p);

