% PURPOSE: remove DC offset (e.g., mean signal) in fnirs data
% AUTHOR: Don Rojas, Ph.D.
% INPUT: 
%   data, N timepoint x N channel array of data to offset correct
% OUTPUT:
%   odata, offset corrected data, same size as input
% HISTORY:
%   08/06/2024 - revised to switch row/column to be integrated with raw
%                data structure
function odata = nirx_offset(data)
nchn  = size(data,2);
npnts = size(data,1);
odata = zeros(nchn,npnts);
mdata = mean(data,1);
odata = data - repmat(mdata,npnts,1); % remove mean