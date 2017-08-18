function nirx_plot_optode3d(XYZ,S,N,varargin)
% PURPOSE: plots 3d circles on a surfaces to represent optodes
% REQUIRED INPUTS:
% XYZ is n x 3 array of locations to plot circles
% S is n x 3 array surface vertices
% N is n x 3 array of surface normals
% OPTIONAL INPUTS (supplied as option/argument pairs):
% 'facealpha', a vector, length n, of transparencies to plot for the
%       center of each circle, or a scalar to plot all circles: default =
%       .95
% 'edgecolor', an array, length n x 3, of colors to plot for the edges of the
%       circles, or a 1 x 3 vector to plot for all circle edges: default = [0 1
%       0]
% 'facecolor', an array, length n x 3, of colors to fill the circles, or a 
%       1 x 3 vector to plot for all circles: default = [1 0
%       0]
% 'radius', the radius in mm of the circles to plot, a scalar: default = 6
% EXAMPLE 1: nirx_plot_optode3d(XYZ,S,N); uses default settings
% EXAMPLE 2: nirx_plot_optode3d(chpos,scalp.vertices,N, 'edgecolor',[1 1 0],'facecolor',[0 1 1],...
%    'facealpha',.5); % changes defaults

% defaults
hold on;
r = 6; % circle radius in mm
fa = .95; % transparency
ec = [0 1 0]; % edge color
fc = [1 0 0]; % fill color
offset = 10; % slight offset in mm so circle surface does not intersect surface S
theta = linspace(0,2*pi).';

% check for minimum required inputs
if nargin < 3
    error('Three arguments must be supplied to this function!');
end

% sort option/arg pairs
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for i=1:2:optargin
            switch lower(varargin{i})
                case 'facealpha'
                    fa = varargin{i+1};
                case 'edgecolor'
                    ec = varargin{i+1};
                case 'facecolor'
                    fc = varargin{i+1};
                case 'radius'
                    r = varargin{i+1};
                otherwise
                    error('Invalid option!');
            end
        end
    end
end
    
% colors and transparencies
Npnts = size(XYZ,1);
if size(fc,1) == 1
    fc = repmat(fc,Npnts,1);
end
if size(ec,1) == 1
    ec = repmat(ec,Npnts,1);
end
if length(fa) == 1
    fa = repmat(fa,Npnts,1);
end

% loop through locations, plotting circles
for ii=1:Npnts
    % find point that is minimum Euclidean distance from XYZ point to
    % surface point
    point = XYZ(ii,:);
    [~,ind]=min(sqrt((S(:,1) - point(1)).^2 + (S(:,2) - point(2)).^2 + (S(:,3) - point(3)).^2));
    % choose that surface point
    point = S(ind,:);
    n = N(ind,:);
    % project the point slightly away from surface
    point(1) = point(1) + offset * -n(1);
    point(2) = point(2) + offset * -n(2);
    point(3) = point(3) + offset * -n(2);
    T = null(n).';
    V = bsxfun(@plus,r*(cos(theta)*T(1,:)+sin(theta)*T(2,:)),point);
    fill3(V(:,1),V(:,2),V(:,3),fc(ii,:), 'FaceAlpha', fa(ii),'EdgeColor',ec(ii,:));
end

end