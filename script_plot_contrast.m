% plots contrasts on 3d circles at scalp, fills them with colors based on
% t-values if non-zero, sets transparency to full if value is zero to
% indicate non-significance.

contrast = 'con_0001_tvals.mat'; % name of your contrast to plot
load(contrast);

% surfaces from spm
spm_dir = fullfile(spm('dir'),'canonical');
scalp = gifti(fullfile(spm_dir, 'scalp_2562.surf.gii'));
cortex = gifti(fullfile(spm_dir,'cortex_20484.surf.gii'));

braincolor = [240 175 105]./255; % looks more like a cadaver brain
%braincolor = [200 120 105]./255; % pinker look

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
plotted_vertices = scalp.vertices;
plotted_vertices(:,3) = plotted_vertices(:,3) - 10;
s = patch('vertices',plotted_vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
s.FaceLighting = 'gouraud';
alpha(s,.4);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
c.FaceLighting = 'gouraud';
camlight left;
%lighting gouraud;
rotate3d on;

% get surface normals
N = patchnormals(scalp);

% set face alphas
fa = zeros(1,length(scalp.vertices));
ind = find(mvals);
fa(ind) = 1;

% plot
nirx_plot_optode3d(chpos,scalp.vertices,N, 'edgecolor',[0 0 1],'facecolor',mvals,...
    'facealpha',fa,'label','T statistic');
view(-90,0);

% to set T stat range consistently between contrasts, use caxis
caxis([-3 3]); % min and max should be min/max across all contrasts you want to plot together