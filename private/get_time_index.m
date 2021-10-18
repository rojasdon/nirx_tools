function tind = get_time_index(tvec,t)
% function to return time index from structure when input t is in ms/s/etc  

    if isa(tvec,'double')
            tind = get_index(tvec,t);
    else
        error('Input does not contain time vector!');
    end

end

function index = get_index(arr,val)
% function to return index of nearest array value
% will return index of nearest rounded down value (e.g., if arr = 1:2:10 and
% val = 2, then index will = 1, not 2. This behavior is only dramatic for
% whole numbers

    % prevent NAN evaluation errors
    if isnan(val)
      error('Value to search for must not be nan!')
    end

    % simplify search
    arr = arr(:);

    if val<max(arr)
      [~, index] = min(abs(arr(:) - val));
    else
      [~, tmpind] = max(flipud(arr));
      index = length(arr) + 1 - tmpind;
    end

end