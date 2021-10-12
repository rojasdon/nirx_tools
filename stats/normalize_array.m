function [normalized, scaled] = normalize_array(data,x,y)
    % normalize input from 0 to 1
    m = min(data);
    r = max(data) - m;
    normalized = (data - m) / r;
    
    % scale to between x and y
    r2 = y - x;
    scaled = (normalized * r2) + x;
end