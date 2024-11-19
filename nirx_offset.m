% PURPOSE: remove DC offset (e.g., mean signal) in fnirs data
% AUTHOR: Don Rojas, Ph.D.
% INPUT: 
%   data, N wavelength x N timepoint x N channel array of data to offset correct
% OUTPUT:
%   odata, offset corrected data, same size as input
% HISTORY:
%   08/06/2024 - revised to switch row/column to be integrated with raw
%                data structure
%   10/30/2024 - revision to further conform to row/column order for raw
%                data
%   11/19/2024 - revised to allow 2-dimensional or 3-dimensional data
%                (default)
% TODO: extend to allow corrections on one dimensional data as well
function odata = nirx_offset(data)

% dimensions
s = size(data);
if numel(s) < 3
    nwl = 1;
    nchn = s(2);
    npnts = s(1);
    tmp(nwl,:,:) = data; % make it 3-dimensional
    data = tmp;
    clear tmp;
else
    nchn  = s(3);
    npnts = s(2);
    nwl = s(1);
end
odata = zeros(nwl,npnts,nchn);
% remove mean
for wl = 1:nwl
    mdata = mean(data(wl,:,:));
    odata(wl,:,:) = data(wl,:,:) - repmat(mdata,1,npnts); % remove mean
end
% reformat if needed
if numel(s) < 3
    odata = squeeze(odata);
end