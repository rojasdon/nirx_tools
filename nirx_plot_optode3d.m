function nirx_plot_optode3d(XYZ,S,N)
% plots 3d circles on a surfaces to represent optodes
% XYZ is n x 3 array of locations to plot circles
% S is n x 3 array surface vertices
% N is n x 3 array of surface normals

    % defaults
    hold on;
    r = 6;
    offset = 10; % slight offset in mm so circle surface does not intersect other surface
    theta = linspace(0,2*pi).';
    
    % color scaling
    Npnts = size(XYZ,1);
    map = zeros(Npnts,3);
    map(1:Npnts,1) = linspace(.5,1,Npnts)';
    C=[(1:Npnts)'./Npnts zeros(Npnts,1) zeros(Npnts,1)];
    
    % loop through locations
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
        fill3(V(:,1),V(:,2),V(:,3),C(ii,:), 'FaceAlpha', 0,'EdgeColor','b')
    end
end