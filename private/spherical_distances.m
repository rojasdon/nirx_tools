% function pseudo code for shortest path on surface
% two alternatives: 1) 3d mesh, use Djikstra path, or 2) fit sphere to 3d,
% then use haversine formula

% haversine approach
1. Load 3d points of sources and detectors
2. Fit sphere to point array
3. Convert cart to spherical X,Y,Z to r, theta (latitude), and phi (longitude)
    r = sqrt(x^2 + y^2 + z^2);
    th = atan(y/z);
    phi = acos(z/r); % maybe not necessary
3. Find nearest surface intersection of each S-D pair of points in sphere coordinates 
    this is just center of fit sphere to point in Cart coord. geo dist, minus r. then convert to sphere coord.
4. Haversine distance between each S-D pair 

% could use sphereFit. Or, adapt code here: https://lucidar.me/en/mathematics/least-squares-fitting-of-sphere/
with proper credit

For #3, https://math.stackexchange.com/questions/1919177/how-to-find-point-on-line-closest-to-sphere