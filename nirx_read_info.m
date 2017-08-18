function nirsInfo = nirx_read_info(basename)
% function to read NIRx _nirsInfo.mat file

% load file
nirsInfo = [];
info_file = [basename '_nirsInfo.mat'];
if exist(info_file,'file')
    load([basename '_nirsInfo.mat']);
else
    error('File not found!');
end
end