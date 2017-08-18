% function to read NIRx topo layout files
function [S,D] = nirx_read_tpl(file)
    M      = dlmread(file);
    S      = [];
    D      = [];
    for ii = 1:numel(M)
        tpl = num2str(M(ii));
        switch length(tpl)
            case 1
                tpl = ['000' tpl];
            case 2
                tpl = ['00' tpl];
            case 3
                tpl = ['0' tpl];
            otherwise
                tpl = tpl;
        end
        S(ii) = str2num(tpl(1:2));
        D(ii) = str2num(tpl(3:4));
    end
    ind = find(S == 0);
    if ~isempty(ind)
        S(ind) = [];
        D(ind) = [];
    end
    [S sind] = sort(S);
    D = D(sind);
    S = S';
    D = D';
    for ii = 1:length(S)
        nums(ii)=str2num(sprintf('%d%d',S(ii),D(ii)));
    end
    nchan = length(unique(nums));
    fprintf('There are %d channels in the topo display file\n',nchan);
end