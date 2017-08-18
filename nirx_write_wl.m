function nirx_write_wl(basename,data)
% function to write wl1 and wl2 files for nirx
% basename = base of filename to write w/o ext
% data = 2 x npoint x nchan array

% write data
fprintf('\nWriting data to .wl1 file...');
dlmwrite([basename '.wl1'],squeeze(data(1,:,:)),'delimiter',' ');
fprintf('done\n');
fprintf('Writing data to .wl2 file...');
dlmwrite([basename '.wl2'],squeeze(data(2,:,:)),'delimiter',' ');
fprintf('done\n');

end