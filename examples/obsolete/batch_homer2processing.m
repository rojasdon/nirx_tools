% example script to batch process data via homer2

% defaults
plotfig = 1; % set to produce an example plot of the last dataset
timewin = [-5 18]; % set to block average window (i.e., prestim + time of your block), in s
sr = 3.6765; % your sampling rate

% directories and files
file_filter = '*_dsel.nirs';
basedir = spm_select(1,'dir','Select base directory');
cd(basedir);
selected_directories = spm_select ([1 inf], 'dir','Select Directories',{},basedir);

% loop over subjects
nsub = size(selected_directories,1);
for sub = 1:nsub
    % change directory
    cdir = deblank(selected_directories(sub,:));
    cd(cdir);
    
    % get filename and load
    file = dir(file_filter);
    [~,base,ext] = fileparts(file(1).name);
    load([base '.nirs'],'-mat');
    
    % change light intensity to optical density
    dod = hmrIntensity2OD(d);

    if ~exist('tIncMan','var')
        tIncMan = ones(length(t),1);
    end
    
    % motion artifacts (PCA approach)
    [tIncAuto] = hmrMotionArtifact(dod,t,SD,tIncMan,0.5,1,50,5);
    [dod,svsMotion,nSVMotion] = hmrMotionCorrectPCA(SD,dod,tIncAuto,0.8);
    
    % reject segments with artifacts
    [s,tRangeStimReject] = enStimRejection(t,s,tIncAuto,tIncMan,[-5  18]);
    
    % bandpass filter
    dod = hmrBandpassFilt(dod,t,0.02,0.50);
    
    % Beer-Lambert law
    dc = hmrOD2Conc(dod,SD,[6  6]); % dc = ntime x nconc x nchan array

    % average
	[dcAvg,dcAvgStd,tHRF,nTrials,dcSum2] = hmrBlockAvg(dc,s,t,[-5  18]);
    % dcAvg = ntime x nconc x nchan x ncondition averages

    % save results
    save([base '_homer2.mat'],'dod','dcAvg','dcAvgStd','tHRF','nTrials','dcSum2');
    
end

if plotfig
    figure('color','white');
    plot(tHRF,squeeze(dcAvg(:,1:3,1,1))); % plots channel 1 average, HbO,HbR&HbT, for condition 1
    xlabel('Time (s)');
    ylabel('mMol*mm');
    title('Channel 1 Average, Condition 1');
    legend({'HbO','HbR','HbT'});
end