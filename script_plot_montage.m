% plots montage as 3d circles at scalp

% colors to use
source_color = [1 0 0];
detector_color = [0 1 0];
chan_color = [1 1 0];
back_color = [0 0 0];
% braincolor = [240 175 105]./255; % looks more like a cadaver brain
braincolor = [200 120 105]./255; % pinker look

% surfaces from spm
spm_dir = fullfile(spm('dir'),'canonical');
scalp = gifti(fullfile(spm_dir, 'scalp_2562.surf.gii'));
cortex = gifti(fullfile(spm_dir,'cortex_20484.surf.gii'));

% channel and optode locations
[hline,lbl,pos] = nirx_read_chpos('optode_positions.csv');
chpairs = nirx_read_chconfig('ch_config.txt');
chpos = nirx_compute_chanlocs(lbl,pos,chpairs);
sind = [];
dind = [];
for ii=1:length(lbl)
    if lbl{ii}{1}(1)=='S'
        sind = [sind ii];
    end
end
dind = setdiff(1:length(lbl),sind);

% get surface normals
N = patchnormals(scalp);

% plots
figure('color',back_color);
subplot(2,2,1);
% plot sources, detectors, and channels
nirx_plot_optode3d(pos(sind,:),scalp.vertices,N, 'edgecolor',source_color,'facecolor',[0 0 0],...
    'facealpha',0);
nirx_plot_optode3d(pos(dind,:),scalp.vertices,N, 'edgecolor',detector_color,'facecolor',[0 0 0],...
    'facealpha',0);
% plot scalp
s = patch('vertices',scalp.vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
alpha(s,.4);
axis image off; hold on;
% plot brain
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
axis image off; hold on;
camlight left;
lighting gouraud;
rotate3d on; view(-90,0);
% repeat plots with different view
subplot(2,2,2);
nirx_plot_optode3d(pos(sind,:),scalp.vertices,N, 'edgecolor',source_color,'facecolor',[0 0 0],...
    'facealpha',0);
nirx_plot_optode3d(pos(dind,:),scalp.vertices,N, 'edgecolor',detector_color,'facecolor',[0 0 0],...
    'facealpha',0);
s = patch('vertices',scalp.vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
alpha(s,.4);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
axis image off; hold on;
camlight right;
lighting gouraud;
rotate3d on; view(90,0);
% now plot the channel locations
subplot(2,2,3);
nirx_plot_optode3d(chpos,scalp.vertices,N, 'edgecolor',chan_color,'facecolor',[0 0 0],...
    'facealpha',0);
s = patch('vertices',scalp.vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
alpha(s,.4);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
axis image off; hold on;
camlight left;
lighting gouraud;
rotate3d on; view(-90,0);
subplot(2,2,4);
nirx_plot_optode3d(chpos,scalp.vertices,N, 'edgecolor',chan_color,'facecolor',[0 0 0],...
    'facealpha',0);
s = patch('vertices',scalp.vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
alpha(s,.4);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
axis image off; hold on;
camlight right;
lighting gouraud;
rotate3d on; view(90,0);




