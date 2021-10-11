function nirx_write_ch_config(chfile,hdr)
% writes a NIRX_configuration text file in form of:
% S#, D#, 1 row per channel, with header
% inputs:
%   chfile = name of file to write
%   hdr = header from nirx_read_hdr

fp = fopen(chfile,'w');
nlong = size(hdr.longSDpairs,1);
for ii=1:nlong
    fprintf(fp,'%d\t%d\n', hdr.longSDpairs(ii,1),...
        hdr.longSDpairs(ii,2));
end
fclose(fp);

end