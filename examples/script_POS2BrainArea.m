% Script to read a POS.mat file, and using the R.ch.xyzC locations, find
% the nearest brain area to a channel using a specified atlas

% TODO: 3d plot channels and brain atlas using nice 3d routines in my nirx
% code - need aal.lut

clear;
display_fig = 0;


% read POS.mat file
posfile = spm_select(1,'any');
load(posfile);
clocs = R.ch.xyzC; % these coordinates are the ones projected to the MNI brain surface by spm_fnirs
nchans = size(R.ch_sd,1);

% read atlas file
hdr  = spm_vol_nifti(spm_select(1,'image','Select atlas file...'));
vol  = spm_read_vols(hdr);

% read atlas text file
[~, base, ext] = fileparts(hdr.fname);
label_file = [base ext '.txt'];
fid = fopen(label_file,'r');
formatSpec = '%f%s%d%[^\n\r]';
delimiter = ' ';
dataArray = textscan(fid, formatSpec, 'Delimiter', delimiter, ...
    'MultipleDelimsAsOne', true, 'TextType', 'string',  'ReturnOnError', false);
atlas = table(dataArray{1:end-1}, 'VariableNames', {'labelnum','labelname','labelcolor'});
fclose(fid);

% for channel locations, find corresponding voxel locations
clocs = [clocs;ones(1,length(clocs))];
vox = round(inv(hdr.mat)*clocs); 

% find indices of non-zero voxels in atlas
nz_ind = find(vol);
nz_roi = vol(nz_ind); % atlas number for each non-zero

% convert indices into voxel subscripts
[nz_x,nz_y,nz_z] = ind2sub(hdr.dim,nz_ind);
nz_xyz = [nz_x nz_y nz_z];

% find nearest non-zero voxel subscript to each channel. Note that vox variable  would be sufficient,
% except some channels are not quite within the boundaries of the atlas
% brain
nearest_atlas_index = zeros(1,nchans);
md = zeros(1,nchans);
for ii = 1:nchans
    p = vox(1:3,ii);
    d = sqrt((p(1) - nz_xyz(:,1)).^2 +(p(2) - nz_xyz(:,2)).^2 +(p(3) - nz_xyz(:,3)).^2); % Euclidean distance
    [md(ii),mi] = min(d);
    [tmp,si] = sort(d);
    sd = tmp(1:5); si = si(1:5);  
    nearest_mm = hdr.mat*[nz_xyz(mi,:) 1]';
    nearest_atlas_index(ii) = vol(nz_ind(mi)); % this is the region number closest to the channel 
                                               % and index to atlas label
end

% print out list of channels and closest brain structures, to command
% window and to file
out = 'ChanPos2BrainArea.txt';
fp = fopen(out,'w');
fprintf('Channel\tStructure\tDistance (mm)\n');
fprintf(fp,'Channel\tStructure\tDistance (mm)\n');
for ii = 1:nchans
    fprintf('%d\t%s\t%.2f\n',ii,atlas.labelname(nearest_atlas_index(ii)),md(ii));
    fprintf(fp,'%d\t%s\t%.2f\n',ii,atlas.labelname(nearest_atlas_index(ii)),md(ii));
end
fclose(fp);

% figure with labeling and brain - probably want to do this with a surface
% based atlas - does aal have labeling on a surface?
if display_fig
    scatter3(clocs(1,:),clocs(2,:),clocs(3,:));
    hold on;
    text(clocs(1,:),clocs(2,:),clocs(3,:)+1.5,string(num));
    axis image off;
end