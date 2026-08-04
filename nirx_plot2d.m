function hnd = nirx_plot2d(data,coords,labels,varargin)
% PURPOSE:   plots 2D channel map of sensor data
% AUTHOR:    Don Rojas, Ph.D.  
% INPUT:     Required: data, to be plotted, 1 x nchan vector, if data is
%            empty [], then function only plots coordinates supplied.
%            coords = 3d or 2d coordinates for plotting nchan x 2 or 3 array
%            'labels', nchan string array of chan labels S1...Sn, D1...Dn
%            'altlabels', nchan string array of alternative names if you
%               want to plot them, e.g., EEG 10-20 naming convention
%            'locs', 'on|off', chan locations plotted
%            'cbar' 'on|off', color bar
%            'channels', SD pairs for channel mapping
%            'channelcolors', nchannel x 3 vector of rgb triplets for
%               plotting channel colors (e.g., [1 0 0] for red), could be
%               used to indicate ROI, or to indicate significance, bad
%               channels, etc.
%            'chanlinestyle', nchannel x 1 cell array of symbols used in
%               matlab for line styles (e.g., "-","--",":" & -.");
%            'sourcecolor', 1 x 3 rgb triplet
%            'detcolor', 1 x 3 rgb triplet
%            'mark' {1 x n} channel vector of channels to mark in red by
%             name of channel
% OUTPUT:    handle to figure
% EXAMPLES:  fig = nirx_plot2d(data,coords,'locs','on') will produce a flatmap projection of
%               the topography of the data with the channel coordinates marked on the
%               plot
% SEE ALSO:  

% HISTORY:   12/02/2017 - Adapted from similar function in megtools toolbox
%            10/10/2022 - Added flexibility to just plot coords without data
%            08/06/2024 - fixed 10/10 to work
%            08/03/2026 - added support for color of optodes, overplotting simple
%            head, labels, channel plotting

% defaults
usehead = 1;
locs   = 1;
labelson = 0;
cbar   = 0;
mark   = 0;
epoch  = 0;
offset = 15;
channelplot = 0;
channelcolor = [0 0 0]; % default channel color
chanlines = {'-'}; % default solid line
s_color = [1 0 0];
d_color = [0 0 1];
dsize = 50; % default dot size for optodes
csize = 1; % default line size for channels

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
                case 'altlabels'
                    labelson = 1;
                    altlabels = varargin{ii+1};
                case 'channels'
                    channelplot = 1;
                    SD = varargin{ii+1};
                case 'channelcolors'
                    channelcolor = varargin{ii+1};
                case 'chanlinestyle'
                    chanlines = varargin{ii+1};
                case 'sourcecolor'
                    s_color = varargin{ii+1};
                case 'detcolor'
                    d_color = varargin{ii+1};
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

% display 2d head template
[pth,~,~]=fileparts(which('nirx_defaults'));
top = imread(fullfile(pth,'templates','Cartoon_Head_Top.jpg'));
if usehead
    h = figure('color','w');
    imagesc(top);
    ax = gca;
    ax.Visible = 'off';
    axis('equal');
end
ax.FontSize = 10;
[rows, columns, ~] = size(top);

% sort sources from detectors
sources = find(labels.contains("S"));
detectors = find(labels.contains("D"));

if size(coords,2) == 3
    loc2d = nirx_coords2D(coords);
elseif size(coords,2) == 2
    loc2d = coords;
else
    error('Channel coordinates must be have x,y or x,y,z locations!');
end

% rescale the optode coordinates to the size of the figure
columns = ceil(columns * .95); % reduce size a bit to fit nicely within head graphic
rows = ceil(rows * .95);
loc2d(:,1) = max(loc2d(:,1)) + min(loc2d(:,1)) - loc2d(:,1); % mirror about midline axis
loc2d(:,1) = columns - rescale(loc2d(:,1), 1, columns - 50); % 75 is nice l to r nudge for view
loc2d(:,2) = rows - rescale(loc2d(:,2), 1, rows - 180); % 180 is nudge to nice top to bottom view

% plot channels first (looks better if circles are overplotted)
hold on;
src2d = loc2d(sources,:);
det2d = loc2d(detectors,:);
if numel(channelcolor) == 3
    c_colors = repmat(channelcolor,length(SD),1);
else
    c_colors = channelcolor;
end
if length(chanlines) == 1
    chanlines = repmat(chanlines,length(SD),1);
else
    c_colors = channelcolor;
end
if channelplot
    for chn = 1:length(SD)
        src = SD(chn,1);
        det = SD(chn,2);
        line(ax,[src2d(src,1) det2d(det,1)],[src2d(src,2) det2d(det,2)],'color',c_colors(chn,:),'linewidth',csize,'linestyle',chanlines{chn});
    end
end

% plot optodes
h1 = scatter(ax,src2d(:,1),src2d(:,2),dsize,'MarkerEdgeColor',s_color,'MarkerFaceColor',s_color);
h2 = scatter(ax,det2d(:,1),det2d(:,2),dsize,'MarkerEdgeColor',d_color,'MarkerFaceColor',d_color);

% labels
if labelson
    text(ax,loc2d(:,1)+offset,loc2d(:,2)+offset,altlabels);
    %text(ax,loc2d(:,1)+offset,loc2d(:,2)+offset,labels);
end

% legend
legend([h1,h2],{'Sources','Detectors'},'Location','southoutside','Box','off');