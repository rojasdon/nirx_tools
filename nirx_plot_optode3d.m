function [h,XYZoffset] = nirx_plot_optode3d(XYZ,S,N,varargin)
% PURPOSE: plots 3d circles on a surfaces to represent optodes
% AUTHOR: Don Rojas
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
% 'radius', the radius in mm of the circles to plot, a scalar: default = 5
% 'offset', the amount of surface offset, in mm, for each optode: default =
%       10
% 'cbar', for colorbar. If supplied, a colorbar is
%   created with a label from the next argument
% 'labels', to label each plotted point, size must be 1 x n cell where n = size of S input
% OUTPUTS:
%   XYZoffset = points offset for nicer plotting (avoids intersection with
%   surfaces)
% EXAMPLE 1: nirx_plot_optode3d(XYZ,S,N); uses default settings
% EXAMPLE 2: nirx_plot_optode3d(chpos,scalp.vertices,N, 'edgecolor',[1 1 0],'facecolor',[0 1 1],...
%    'facealpha',.5); % changes defaults
% Note: with optode labeling, currently you should use a lower alpha so
%   that the labels are readable.
% Revision History
% 03/01/2022 - Added text label functionality, corrected bug with edge
%              coloring that only allowed a single scalar
% 08/12/2024 - revised for greater flexibility, adding axis specification,
%              handle output and offset xyz output for line plotting

% defaults
ax = 0;
r = 5; % circle radius in mm
fa = .95; % transparency
ec = [0 1 0]; % edge color
fc = [1 0 0]; % fill color
offset = 10; % slight offset in mm so circle surface does not intersect surface S
theta = linspace(0,2*pi,size(S,1)).';
th_s = length(theta); 
facelight = 'none';
plotlegend = 0;
plotlabels = 0;

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
                case 'offset'
                    offset = varargin{i+1};
                case 'cbar'
                    cbarlabel = varargin{i+1};
                    plotlegend = 1;
                case 'labels'
                    labels = varargin{i+1};
                    plotlabels = 1;
                case 'axis'
                    ax = varargin{i+1};
                otherwise
                    error('Invalid option: %s!',varargin{i});
            end
        end
    end
end

% axis handle
if ~isgraphics(ax,'Axes') % axis handle not supplied
    ax = gca;
end
hold(ax,'on');

% colors and transparencies
Npnts = size(XYZ,1);
if numel(fc) == 3 % all one color
    fc = repmat(fc,Npnts,1);
    cmap = colormap(ax); % use default
else % scale colormap to supplied array
    cmap = parula(Npnts);       
end

% deal with input variability
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
    [~,ind] = min(sqrt((S(:,1) - point(1)).^2 + (S(:,2) - point(2)).^2 + (S(:,3) - point(3)).^2));
    % choose that surface point
    point = S(ind,:);
    n = N(ind,:);
    % project the point slightly away from surface
    point(1) = point(1) + offset * -n(1);
    point(2) = point(2) + offset * -n(2);
    point(3) = point(3) + offset * -n(2);
    XYZoffset(ii,:) = point;
    T = null(n).';
    V = bsxfun(@plus,r*(cos(theta)*T(1,:)+sin(theta)*T(2,:)),point);
    fa_tmp = repmat(fa(ii),th_s,1);
    ec_tmp = repmat(ec(ii,:),th_s,1);
    fc_tmp = repmat(fc(ii),th_s,1);
    h = fill3(ax,V(:,1),V(:,2),V(:,3),fc_tmp(ii,:), 'FaceAlpha', fa_tmp(ii),'EdgeColor',ec_tmp(ii,:),'linewidth',1.5);
    h.FaceLighting = facelight;
    if plotlabels
        loc = double(point);
        text(ax,loc(1)+2,loc(2)+2,loc(3)+2,labels(ii));
    end
end

colormap(ax,cmap); 
if plotlegend
    h = colorbar(ax,'SouthOutside'); ylabel(h,cbarlabel);
end
hold(ax,'off');

end