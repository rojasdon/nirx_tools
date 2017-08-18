function nirs_data = nirx2nirsspm(nirs, nirs_raw)
% convert nirx nirscout data to nirs_spm format

% nirs_spm structure
nirs_data               = [];
nirs_data.oxyData       = squeeze(nirs_raw(1,:,:));
nirs_data.dxyData       = squeeze(nirs_raw(2,:,:));
nirs_data.nch           = nirs.nchan;
nirs_data.fs            = nirs.sr;
nirs_data.wavelength    = [760 850];
nirs_data.distance      = 3.0; % TODO - needs flexibility
nirs_data.DPF           = [7.25 6.38]; % TODO - needs flexibility

end