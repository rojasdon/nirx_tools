function chns = nirx_read_chconfig(file)
% reads a csv file of optode positions and returns locations
% assumes structure Optode,X,Y,Z with single header line
% file = name of file to read
% ex: chns = nirx_read_chconfig('ch_config.txt');

    fp = fopen(file);
    fgetl(fp); % skip header line
    chns = [];
    ii = 1;
    while ~feof(fp)
        tmp = fgetl(fp);
        C = textscan(tmp,'%d %d %d','delimiter',',');
        chns(ii,:) = [C{1} C{2} C{3}];
        ii = ii + 1;
    end
    fclose(fp);
end