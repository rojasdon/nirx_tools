function [nirs,nirx] = nirx_write_nirs(base)
% function to take nirx info and write nirs (homer) format
% base = base name of files from nirx - should be evt, hdr, info, tpl, wl
% files minimum

% test if necessary files exist, read if found
evtfile = [base '.evt'];
wl1file = [base '.wl1']; % need to add var for 3+ wl systems
wl2file = [base '.wl2'];
hdrfile = [base '.hdr'];
if ~exist(evtfile,'file')
    error('Cannot find: %s',evtfile); 
else
    [nirx.onsets,nirx.vals] = nirx_read_evt(evtfile);
end
if ~exist(hdrfile,'file')
    error('Cannot find: %s',hdrfile); 
else
    nirx.hdr = nirx_read_hdr(hdrfile);
end
if ~exist(wl1file,'file') || ~exist(wl2file,'file') 
    error('Cannot find .wl1 or .wl2 file!');
else
    [nirx.raw,nirx.cols,nirx.S,nirx.D] = nirx_read_wl(base,nirx.hdr);
end

% construct nirs structure
nirs = [];
nsamples = size(nirx.raw,2);
nirs.t = 1:nsamples;
nirs.t = nirs.t*(1/nirx.hdr.sr);

end
