function d = great_circle_dist(r, point1, point2)
% r is radius
% point1 and point2 are 2 element vectors of theta/latitude and
% phi/longitude, e.g., [2.54 1.05]

    lat1 = point1(1);
    lat2 = point2(1);
    lon1 = point1(2);
    lon2 = point2(2);

    delta_lat = lat2 - lat1;
    delta_lon = lon2 - lon1;

    a = sin(delta_lat/2)^2 + cos(lat1) * cos(lat2) * sin(delta_lon/2)^2;
    c = 2 * atan2(sqrt(a),sqrt(1-a));
    d = r * c;

end