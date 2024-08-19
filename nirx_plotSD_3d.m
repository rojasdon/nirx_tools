function nirx_plotSD_3d(pos,sources,varargin)
% plots optodes as spheres, with option to plot all channel pairs using 3d
% cylinders for nice plotting of montages
% AUTHOR: Don Rojas
% INPUT: pos, n_optode by 3 array of coordinates for optodes
%        sources, 1 x n list of source indices
% OPTIONAL, in pairs
%   'channels', SD pairs, nchan x 2 list of pairs, e.g., from hdr.SDpairs
%   'surface', surface, n_optode x 1 structure array of surface normals and
%       vertices, e.g., S.vertices (n_vertices x 3) and S.normals
%       (n_vertices x 1). Used to offset optodes from a surface such as
%       scalp. If supplied in structure, S.offset is an override to default
%       offset = 5 mm, indicating how far to offset optodes from supplied
%       surface. Optodes are projected away along their surface normal.

% defaults
setlights = 0;
plotchan = 0;
plotlabels = 0;
offset = 10; % mm offset normal to surface to avoid optode/channel intersection when plotting over brain/scalp
Srad = 5; % sphere radius mm
Crad = 2; % cylinder radius mm
N = 20; % elements in sphere and cylinder
fc = [0 1 0]; % green is default color for channels

% sort option/arg pairs
if ~isempty(varargin)
    optargin = size(varargin,2);
    if (mod(optargin,2) ~= 0)
        error('Optional arguments must come in option/value pairs');
    else
        for option=1:2:optargin
            switch lower(varargin{option})
                case 'surface'
                    S = varargin{option+1};
                case 'facecolor'
                    fc = varargin{option+1};
                case 'radius'
                    r = varargin{option+1};
                case 'offset'
                    offset = varargin{option+1};
                case 'channels'
                    SDpairs = varargin{option+1};
                    plotchan = 1;
                case 'labels'
                    labels = varargin{option+1};
                    plotlabels = 1;
                case 'axis'
                    ax = varargin{option+1};
                case 'lights'
                    state = varargin{option+1};
                    switch state
                        case 'on'
                            setlights = 1;
                        case 'off'
                            setlights = 0;
                    end
                otherwise
                    error('Invalid option: %s!',varargin{option});
            end
        end
    end
    
    % variables
    n_opt = size(pos,1);
    detectors = setdiff(1:n_opt,sources);
    type = zeros(1,n_opt);
    type(sources) = 1;
    if plotchan
        fc = repmat(fc,size(SDpairs,1),1);
    end

    % axis handle
    if ~isgraphics(ax,'Axes') % axis handle not supplied
        ax = gca;
    end
    hold(ax,'on');

    % offset optodes if requested
    if exist('S','var')
        for opt=1:n_opt
            % find minimum distance from optode position to surface point
            point = pos(opt,:);
            [~,ind] = min(sqrt((S.coords(:,1) - point(1)).^2 + (S.coords(:,2) - point(2)).^2 + (S.coords(:,3) - point(3)).^2));
            % choose that surface point
            point = S.coords(ind,:);
            n = S.normals(ind,:);
            % project the point slightly away from surface
            point(1) = point(1) + offset * -n(1);
            point(2) = point(2) + offset * -n(2);
            point(3) = point(3) + offset * -n(3);
            pos(opt,:) = point;
        end
    else
        offset = 0;
    end
    
    % create spheres for optodes
    for opt=1:n_opt
        [S(opt).X,S(opt).Y,S(opt).Z] = sphere(N);
        S(opt).X = (S(opt).X * Srad + pos(opt,1));
        S(opt).Y = (S(opt).Y * Srad + pos(opt,2));
        S(opt).Z = (S(opt).Z * Srad + pos(opt,3));
    end

    % plot optodes
    for opt=1:n_opt
        sh(opt)=surf(ax,S(opt).X,S(opt).Y,S(opt).Z);
        sh(opt).EdgeColor = 'none';
        sh(opt).FaceLighting = 'gouraud';
        if type(opt)
            sh(opt).FaceColor = 'r';
        else
            sh(opt).FaceColor = 'b';
        end
    end
    if plotchan
        % create cylinders for each channel
        spos = pos(sources,:);
        dpos = pos(detectors,:);
        nchan = size(SDpairs,1);
        for chn=1:nchan
            pair = SDpairs(chn,:);
            [C(chn).X,C(chn).Y,C(chn).Z]=cylinder2P(Crad,N,spos(pair(1),:),dpos(pair(2),:));
        end
        % plot channels
        for chn=1:nchan
            ch(chn)=surf(ax,C(chn).X,C(chn).Y,C(chn).Z);
            ch(chn).FaceColor = fc(chn,:);
            ch(chn).EdgeColor = 'none';
            ch(chn).FaceLighting = 'gouraud';
        end
    end
    axis(ax,'image');
    if plotlabels
        text(ax,pos(:,1),pos(:,2),pos(:,3)+offset+2,labels,'FontWeight','bold');
    end
    if setlights
        camlight(ax,'left');
        camlight(ax,'right');
        rotate3d(ax,'on');
    end
end