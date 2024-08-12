function pos2d = nirx_coords2D(pos3d)
% PURPOSE: converts 3d coordinates to 2d for flat map projection
% AUTHOR: Don Rojas
% INPUTS:
%   pos3d = n x 3 array of positions
% OUTPUTS:
%   pos2d = n x 2 array of positions
% TODO: 1. Add options to rotate map counter vs clockwise, etc.

% check input
if size(pos3d,2) == 3
    % do projection of 3D positions into 2D map
    pos2d      = double(thetaphi(pos3d')); %flatten
    pos2d(3,:) = []; % remove 3rd dim
    %pos2d(1,:) = pos2d(1,:).* -1; % rotate clockwise 90 (loc2d(1,:) for anti-clockwise)
    pos2d = pos2d';
elseif size(coords,2) == 2
    pos2d = pos3d;
else
    error('Channel coordinates must be have x,y or x,y,z locations!');
end