% plots montage as 3d circles at scalp

% colors to use
optode_color = [1 1 0];
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
subplot(1,2,1);
nirx_plot_optode3d(chpos,scalp.vertices,N, 'edgecolor',optode_color,'facecolor',[1 0 0],...
    'facealpha',.5);
s = patch('vertices',plotted_vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
alpha(s,.4);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
axis image off; hold on;
camlight left;
lighting gouraud;
rotate3d on; view(-90,0);
subplot(1,2,2);
nirx_plot_optode3d(chpos,scalp.vertices,N, 'edgecolor',optode_color,'facecolor',[1 0 0],...
    'facealpha',.5);
s = patch('vertices',plotted_vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
alpha(s,.4);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
axis image off; hold on;
camlight right;
lighting gouraud;
rotate3d on; view(90,0);



