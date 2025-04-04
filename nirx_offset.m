% PURPOSE: To remove DC offset (e.g., mean signal) in fnirs data on a per
%          channel basis
% AUTHOR:  Don Rojas, Ph.D.
% INPUT: 
%   data, N wavelength x N timepoint x N channel array of data to offset
%   correct, see nirx_read_wl.m
% OUTPUT:
%   odata, offset corrected data, same size as input
% HISTORY:
%   08/06/2024 - revised to switch row/column to be integrated with raw
%                data structure
%   10/30/2024 - revision to further conform to row/column order for raw
%                data
%   03/10/2024 - extended to allow corrections on non-raw type data of one or two
%                dimensions, primarily for working with fnirs_dataViewer
%                code
function odata = nirx_offset(data)

% dimensions
s = size(data);
ndim = numel(s);
if ndim > 3
    error('Wrong input dimensions for data. Must =< 3!');
else
    switch ndim
        case 3
            nchn  = s(3);
            npnts = s(2);
            nwl = s(1);
            odata = zeros(nwl,npnts,nchn);
            % remove mean
            for wl = 1:nwl
                mdata = mean(data(wl,:,:));
                odata(wl,:,:) = data(wl,:,:) - repmat(mdata,1,npnts); % remove mean
            end
        case 2
            nchn = s(2);
            npnts = s(1);
            mdata = repmat(mean(data,1),npnts,1);
            odata = data - mdata;
        case 1 % not tested with fnirs_* code yet
            nchn = 1;
            npnts = s;
            mdata = mean(data);
            odata = data - mdata;
    end
end
