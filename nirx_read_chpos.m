function [first, ids, pos] = nirx_read_chpos(file)
% reads a csv file of optode positions and returns locations
% inputs:
%   file = file to read
% outputs:
%   first = header line from file
%   ids = id labels in file
%   pos = n x 3 array of positions

    fp = fopen(file);
    first = fgetl(fp);
    pos = [];
    ii = 1;
    while ~feof(fp)
        tmp = fgetl(fp);
        C = textscan(tmp,'%s %f %f %f','delimiter',',');
        ids{ii} = C{1};
        pos(ii,:) = [C{2} C{3} C{4}];
        ii = ii + 1;
    end
    fclose(fp);
end