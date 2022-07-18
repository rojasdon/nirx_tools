% PURPOSE: remove DC offset (e.g., mean signal) in fnirs data
% AUTHOR: Don Rojas, Ph.D.
% INPUT: 
%   data, N channel x N timepoint array of data to offset correct
% OUTPUT:
%   odata, offset corrected data, same size as input
% 
function odata = nirx_offset(data)
nchn  = size(data,1);
npnts = size(data,2);
odata = zeros(nchn,npnts);
mdata = mean(data,2);
odata = data - repmat(mdata,1,npnts); % remove mean