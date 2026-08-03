function [X, Y, Z] = polygonal_cylinder(P1, P2, r, n)
% polygonal_cylinder  Generate an n-sided cylinder between two points.
%
%   [X, Y, Z] = polygonal_cylinder(P1, P2, r, n)
%   returns coordinate grids for a closed cylinder with an n-gon
%   cross-section, radius r, between points P1 and P2.
%
%   Inputs:
%       P1 - [x,y,z] bottom cap center
%       P2 - [x,y,z] top cap center
%       r  - radius
%       n  - number of polygon sides (>=3)
%
%   Outputs:
%       X, Y, Z - (n+1)-by-2 arrays suitable for surf()
%
%   Example:
%       P1 = [0 0 0]; P2 = [0 0 5];
%       [X, Y, Z] = polygonal_cylinder(P1, P2, 2, 20);
%       surf(X, Y, Z); axis equal; shading interp; camlight; lighting gouraud

    % Make row vectors
    P1 = P1(:).'; 
    P2 = P2(:).';

    % Axis vector
    v = P2 - P1;
    v = v / norm(v); % unit vector

    % Orthonormal basis perpendicular to v
    if abs(dot(v, [0 0 1])) < 0.9
        tmp = [0 0 1];
    else
        tmp = [0 1 0];
    end
    u = cross(v, tmp); u = u / norm(u);
    w = cross(v, u);

    % Angles for polygon
    theta = linspace(0, 2*pi, n+1);

    % Circle points at base (relative coordinates)
    circle = r * (cos(theta(:))*u + sin(theta(:))*w);

    % Two layers: bottom and top
    bottom = P1 + circle;
    top    = P2 + circle;

    % Format for surf: (n+1)-by-2
    X = [bottom(:,1), top(:,1)];
    Y = [bottom(:,2), top(:,2)];
    Z = [bottom(:,3), top(:,3)];
end