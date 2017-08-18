% plots optode and channel locations for montage on an MNI standard head

% surfaces from spm
spm_dir = fullfile(spm('dir'),'canonical');
scalp = gifti(fullfile(spm_dir, 'scalp_2562.surf.gii'));
cortex = gifti(fullfile(spm_dir,'cortex_20484.surf.gii'));

% braincolor = [240 175 105]./255; % looks more like a cadaver brain
braincolor = [200 120 105]./255; % pinker look

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
nirx_plot_optode3d(chpos,S,N,10);

%for i=1:size(N,1)
%    p1=scalp.vertices(i,:); p2=scalp.vertices(i,:)+10*N(i,:);       
%    plot3([p1(1) p2(1)],[p1(2) p2(2)],[p1(3) p2(3)],'g-');
%end 

% plot channels and optodes
%scatter3(pos(sind,1),pos(sind,2),pos(sind,3),300,'g.');
%scatter3(pos(dind,1),pos(dind,2),pos(dind,3),300,'r.');
%scatter3(chpos(:,1),chpos(:,2),chpos(:,3),'xb');




