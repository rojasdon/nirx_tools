% plots optode and channel locations for montage on an MNI standard head

%clear;

filebase = 'NIRS-2021-09-28_001'; % file to plot
offset = 10;

% read header to get the short channels, if any
hdr = nirx_read_hdr([filebase '.hdr']);

% surfaces from spm
spm_dir = fullfile(spm('dir'),'canonical');
scalp = gifti(fullfile(spm_dir, 'scalp_2562.surf.gii'));
cortex = gifti(fullfile(spm_dir,'cortex_20484.surf.gii'));

% braincolor = [240 175 105]./255; % looks more like a cadaver brain
braincolor = [200 120 105]./255; % pinker looking brain

% channel and optode locations
[hline,lbl,pos] = nirx_read_optpos('optode_positions.csv');
chpairs = nirx_read_chconfig('ch_config.txt');
[longpos,shortpos] = nirx_compute_chanlocs(lbl,pos,chpairs,hdr.shortdetindex);
sind = [];
sdind = hdr.shortSDindices;
ldind = hdr.longSDindices;
for ii=1:length(lbl)
    if lbl{ii}{1}(1)=='S'
        sind = [sind ii];
    end
end
dind = setdiff([1:length(pos)],sind);

% plot surfaces
figure('color','white');
s = patch('vertices',scalp.vertices,'faces',scalp.faces,'edgecolor','none',...
        'facecolor',[.8 .8 .8]);
S = s.Vertices;
N = patchnormals(scalp);
alpha(s,.3);
axis image off; hold on; 
c = patch('vertices',cortex.vertices,'faces',cortex.faces,'edgecolor','none',...
        'facecolor',braincolor);
camlight left; camlight right;
lighting gouraud;
rotate3d on;

% plot sources as red - nirx convention
nirx_plot_optode3d(pos(sind,:),S,N,'offset',10,'edgecolor',[1 0 0],...
    'facealpha',.4,'facecolor',[1 0 0],'labels',lbl(sind));

% plot long detectors as red - nirx convention
nirx_plot_optode3d(pos(dind,:),S,N,'offset',10,'edgecolor',[0 1 0],...
    'facealpha',.4,'facecolor',[0 1 0],'labels',lbl(dind));

% plot short detectors as black circles
nirx_plot_optode3d(shortpos,S,N,'offset',offset,'edgecolor',[0 0 0],'facecolor',[1 0 0]);

% plot channels formed
for ii=1:length(longpos)
    chanlabels{ii} = str2cell(num2str(ii),1);
end
nirx_plot_optode3d(longpos,S,N,'offset',12,'edgecolor',[0 0 0],'facecolor',[0 0 1]);

