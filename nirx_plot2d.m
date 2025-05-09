function hnd = nirx_plot2d(data,coords,varargin)
% PURPOSE:   plots 2D channel map of sensor data
% AUTHOR:    Don Rojas, Ph.D.  
% INPUT:     Required: data, to be plotted, 1 x nchan vector, if data is
%           empty [], then function only plots coordinates supplied.
%           coords = 3d or 2d coordinates for plotting nchan x 2 or 3 array
%           'labels', nchan cell array of chan labels, 
%           'locs', 'on|off', chan locations plotted
%           'cbar' 'on|off', color bar
%           'mark' {1 x n} channel vector of channels to mark in red by
%            name of channel
% OUTPUT:    handle to figure
% EXAMPLES:  fig = nirx_plot2d(data,coords,'locs','on') will produce a flatmap projection of
%               the topography of the data with the channel coordinates marked on the
%               plot
% SEE ALSO:  

% HISTORY:   12/02/2017 - Adapted from similar function in megtools toolbox
%            10/10/2022 - Added flexibility to just plot coords without data
%            08/06/2024 - fixed 10/10 to work

% defaults
locs   = 1;
labelson = 0;
cbar   = 0;
mark   = 0;
epoch  = 0;
offset = .1;
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for ii=1:2:optargin
            switch varargin{ii}
                case 'locs'
                    if strcmp(varargin{ii+1},'on')
                        locs = 1;
                    else
                        locs = 0;
                    end
                case 'labels'
                    labelson = 1;
                    labels = varargin{ii+1};
                case 'cbar'
                    if strcmp(varargin{ii+1},'on')
                        cbar = 1;
                    else
                        cbar = 0;
                    end
                case 'mark'
                    mark   = 1;
                    marked = varargin{ii+1};
                otherwise
                    error('Invalid option!');
            end
        end
    end
end

% sort sources from detectors
if labelson
    sources = find(labels.contains("S"));
    detectors = find(labels.contains("D"));
end

if size(coords,2) == 3
    % do projection of 3D positions into 2D map
    loc2d      = double(thetaphi(coords')); %flatten
    loc2d(3,:) = []; % remove 3rd dim
    tmp = loc2d(1,:);
    loc2d(1,:) = loc2d(2,:);
    loc2d(2,:) = tmp; % reverse x,y
    loc2d(2,:) = loc2d(2,:).* -1; % rotate clockwise 90 (loc2d(1,:) for anti-clockwise)
elseif size(coords,2) == 2
    loc2d = coords;
else
    error('Channel coordinates must be have x,y or x,y,z locations!');
end

% grid data across 2d flat map projection
xlin  = linspace(min(loc2d(2,:)),max(loc2d(2,:)));
ylin  = linspace(min(loc2d(1,:)),max(loc2d(1,:)));
[x,y] = meshgrid(xlin,ylin);
if ~isempty(data)
    Z  = griddata(loc2d(2,:),loc2d(1,:),double(data),x,y);
end

% plot result on new figure
if ~isempty(data)
    contourf(x,y,Z,20);
end
hnd = figure('Color','w');
hold on;
if labelson
    for ii=1:length(loc2d)
        % text(loc2d(2,ii)+offset,loc2d(1,ii),labels(ii),'FontSize',8);
    end
end
if locs
    if labelson
        scatter(loc2d(2,sources),loc2d(1,sources),'red');
        scatter(loc2d(2,detectors),loc2d(1,detectors),'blue');
    else
        plot(loc2d(2,:),loc2d(1,:),'.k');
    end
end
if cbar
    bar = colorbar();
    set(get(bar, 'Title'), 'String', 'T');
end
if mark % not currently working
    plot(loc2d(2,cinds),loc2d(1,cinds),'.m');
end
hold off;

end