function nirx_write_ch_config(chfile,hdr)
% writes a ch_config text file in form of:
% Ch#, S#, D#, 1 row per channel, with header
% inputs:
%   chfile = name of file to write
%   hdr = header from nirx_read_hdr

fp = fopen(chfile,'w');
fprintf(fp,'Ch, Source, Detector\n');
for ii=1:hdr.nchan
    fprintf(fp,'%d, %d, %d\n', ii, hdr.SDpairs(ii,1),...
        hdr.SDpairs(ii,2));
end
fclose(fp);

end