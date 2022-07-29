% script to visualize source-detector pairings
clear 

% get data
csvfile = spm_select(1,'any','Select csv file with optode positions',{},pwd,...
    '.*\.csv$');
chfile = spm_select(1,'any','Select ch_config file with chan info',{},pwd,...
    '^ch_.*\.txt$');
[~,id,pos] = nirx_read_chpos(csvfile);
chns = nirx_read_chconfig(chfile);

% find sources and detectors
sind = [];
dind = [];
for ii=1:length(id)
    name = char(id{ii});
    if name(1) == 'S'
        sind = [sind ii];
    else
        dind = [dind ii];
    end
end
S = pos(sind,:);
D = pos(dind,:);
Slabels = id(sind);
Dlabels = id(dind);

% set up figure
figure('color','w','name','SD Pairs');
scatter3(S(:,1),S(:,2),S(:,3),40,'r','*');
hold on;
scatter3(D(:,1),D(:,2),D(:,3),40,'b','*');
axis image;
rotate3d on;
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');

% label the optodes
text(S(:,1),S(:,2),S(:,3),Slabels,'color','r');
text(D(:,1),D(:,2),D(:,3),Dlabels,'color','b');

% draw lines and get distances between SD pairs
for ii = 1:length(chns)
    src = chns(ii,2);
    det = chns(ii,3);
    line([S(src,1) D(det,1)],[S(src,2) D(det,2)],[S(src,3) D(det,3)]);
    dist(ii) = sqrt((S(src,1)-D(det,1))^2 + (S(src,2) - D(det,2))^2 + ...
        (S(src,3) - D(det,3))^2);
end

