% function to write nirx event file (*.evt) given list of onsets and values
% INPUTS
%   file   = .evt filename to write to disk
%   onsets = vector (1 x n or n x 1) of onset times in samples
%   values = vector (1 x n or n x 1) of trigger values, same length as
%            onsets
% OUTPUT
%   a file written to disk with the name corresponding to "file" input
function nirx_write_evt(file,onsets,values)
    
    % open file for writing
    fp = fopen(file,'w');
    
    % translate integers into binary
    binvals = dec2bin(values);
    binvals = fliplr(binvals); % reverse highest bit for nirx
    
    % write to tab delim file
    for ii=1:length(onsets)
        fprintf(fp,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d',...
            onsets(ii),str2num(binvals(ii,1)),str2num(binvals(ii,2)),...
            str2num(binvals(ii,3)),str2num(binvals(ii,4)),...
            str2num(binvals(ii,5)),str2num(binvals(ii,6)),...
            str2num(binvals(ii,7)),str2num(binvals(ii,8)));
        if ii < length(onsets)
            fprintf(fp,'\n');
        end
    end  
    fclose(fp);
end