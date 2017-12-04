function p = thetaphi(p3d)
% THETAPHI Maps 3D points to Theta-Phi plane
% p = thetaphi(p3d)

icent = 0;

%Find center
if icent ~= 0
    Rc = mean(p3d, 2);
else
    Rc = [0;0;0];
end

%New vectors
nv = size(p3d,2);
p3d = p3d-Rc(:,ones(1,nv));

%Map points
ro = sqrt(sum(p3d.*p3d));
theta = acos(p3d(3,:)./ro);
phi = atan2(p3d(2,:),p3d(1,:));

p = [theta.*cos(phi); theta.*sin(phi); ones(size(ro))];
