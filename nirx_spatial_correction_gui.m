% spm-based GUI script for editing a csv optode location file for a subject
% based on a corrected input file. The assumption is that the corrected
% nirx .hdr file has been edited so that fewer channels exist in the .hdr
% channel mask than in the channel config text file (e.g., after running
% hdr=nirx_read_hdr(filename,threshold) on an .hdr file

% Author: Don Rojas, Ph.D.

% read the file information
hdr_file                = spm_select(1,'any','Select NIRx Event File',...
                            '',pwd,'^.*_corrected\.hdr$');
nirs                    = nirx_read_hdr(hdr_file);
chan_ind                = nirs.chnums;
chn_file                = spm_select(1,'any','Select ch_config file',...
                            '',pwd,'^.*ch_config\.txt$');
csv                     = readtable(chn_file);

% select appropriate channels
ntotal  = size(csv,1);
missing = setdiff(1:ntotal,chan_ind);
csv(missing,:) = [];

% renumber channels - FIXME: is this the right thing to do?
for ii=1:ntotal-length(missing)
    csv{ii,1} = ii;
end

% write the new file - first rename original file to _old.csv
header_names=fieldnames(csv);
[pth, nam, ext]=fileparts(chn_file);
movefile(chn_file,[nam '_old' ext]);
fp = fopen(chn_file,'w');
fprintf(fp,'%s, %s, %s\n',header_names{1},header_names{2},header_names{3});
for ii=1:size(csv,1)
    fprintf(fp,'%s, %s, %s\n', num2str(csv{ii,1}), num2str(csv{ii,2}), num2str(csv{ii,3}));
end
fclose(fp);