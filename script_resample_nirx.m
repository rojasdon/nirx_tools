% resample NIRx dataset

clear;

% file to resample
filebase = 'dotp_011';

% defaults
desired_sr = 3.9062;
new_suffix = '_resampled';

% read header
hdr = nirx_read_hdr([filebase '.hdr']);
orig_sr = hdr.sr;

% read raw data without masking
[raw, cols, ~,~] = nirx_read_wl(filebase,hdr,'all');

% resample
ratio = desired_sr/orig_sr;
orig_tx = 1:size(raw,2); orig_tx = orig_tx * 1/orig_sr; orig_tx = orig_tx - (1/orig_sr);
new_tx = 0:1/desired_sr:orig_tx(end);
for ii = 1:2
    for jj = 1:size(raw,3)
        newraw(ii,:,jj) = interp1(squeeze(raw(ii,:,jj)),...
            new_tx,'linear');
    end
end

% write the corrected wl* data to files
nirx_write_wl([filebase new_suffix],newraw);

% write new header
newhdr = hdr;
newhdr.sr = desired_sr;
nirx_write_hdr([filebase new_suffix '.hdr'],newhdr);