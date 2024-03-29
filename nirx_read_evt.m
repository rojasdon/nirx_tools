function [onsets, vals] = nirx_read_evt(file,varargin)
% PURPOSE: function to read nirx event file (*.evt) and return onsets and values
% INPUTS:
%   1. file = *.evt file
% OUTPUTS:
%   1. onsets = onsets in sample points
%   2. vals = trigger values

% read file
M      = dlmread(file);
onsets = M(:,1);
bits   = M(:,2:9);
bitval = [1,2,4,8,16,32,64,128];

vals = zeros(length(onsets),1);
for ii = 1:length(onsets)
    for jj = 1:8
        vals(ii) = vals(ii) + (bits(ii,jj) * bitval(jj));
    end 
end

% end of main
end