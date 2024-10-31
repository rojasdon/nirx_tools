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
% TODO: extend to allow corrections on non-raw type data of one or two
%       dimensions
function odata = nirx_offset(data)

% dimensions
s = size(data);
if numel(s) < 3
    error('Wrong input dimensions for data. Must = 3!');
end
nchn  = s(3);
npnts = s(2);
nwl = s(1);
odata = zeros(nwl,npnts,nchn);
% remove mean
for wl = 1:nwl
    mdata = mean(data(wl,:,:));
    odata(wl,:,:) = data(wl,:,:) - repmat(mdata,1,npnts); % remove mean
end