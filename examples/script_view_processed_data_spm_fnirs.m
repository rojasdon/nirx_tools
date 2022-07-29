% script to view data after preprocessing
clear;

% options
hbsig = 2; % 1 = HbO, 2 = HbR, 3 = HbT
viewspm = 1; % set to 1 to load and SPM.mat and view, or 0 to ignore
roi = [41    42    51    64    78    81    88    89 ...
       90    91    95    97    98    99   104   105 ...
       106   115   116   118]; 

% open a file
file = spm_select(1,'mat','Select NIRS.mat file',{},pwd,'^NIRS.*mat$');
load(file);
if viewspm
    file = spm_select(1,'mat','Select SPM file',{},pwd,'^SPM.*mat$');
    load(file);
end

% apply the temporal processing choices
y = spm_vec(rmfield(Y, 'od'));
y = reshape(y, [P.ns P.nch 3]);
% P.K.H.cutoff = 64;
[fy, P] = spm_fnirs_preproc(y, P);
fy = spm_fnirs_filter(fy, P, P.K.D.nfs);

% view data using spm_fnirs
mask = ones(1, P.nch);
mask = mask .* P.mask;
ch_roi = find(mask ~= 0);
spm_fnirs_viewer_timeseries(y, P, fy, ch_roi);

% view data another way (butterfly plot all data)
figure('color','w');
plot(fy(:,:,hbsig)); xlabel('Time'); ylabel('Intensity');
rmsy = rms(fy(:,roi,1),2);
if viewspm
    figure('color','w');
    desdata = SPM.xX.xKXs.X;
    subplot(2,1,1);
    imagesc(desdata'); colormap gray;
    subplot(2,1,2);
    plot(1:length(rmsy),rmsy);
end
    
    