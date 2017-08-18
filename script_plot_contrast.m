% plots contrasts on 3d circles at scalp

contrast = 'con_0001.mat'; % name of your contrast to plot
load(contrast);

% surfaces from spm
spm_dir = fullfile(spm('dir'),'canonical');
scalp = gifti(fullfile(spm_dir, 'scalp_2562.surf.gii'));
cortex = gifti(fullfile(spm_dir,'cortex_20484.surf.gii'));

braincolor = [240 175 105]./255; % looks more like a cadaver brain
% braincolor = [200 120 105]./255; % pinker look

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

% plot surfaces
figure('color','white');
s = patch('vertices',scalp.vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
alpha(s,.3);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
camlight left; camlight right;
lighting gouraud;
rotate3d on;

% get surface normals
N = patchnormals(scalp);
nirx_plot_optode3d(chpos,scalp.vertices,N);



