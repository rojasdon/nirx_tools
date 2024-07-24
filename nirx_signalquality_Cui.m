function [bad, c] = nirx_signalquality_Cui(hbo,hbr)
% Check data quality using correlation between hbo and hbr as indicator
% if the correlation is strictly -1, then bad channel
% if the correlation is > 0.5, then bad channel
% Input: hbo and hbr are NxM matrix, N is number of scan, and M number of
% channels
% output: array of bad channels
%
% Xu Cui
% 2009/11/25
% todo - integrate this and SCI into main signal quality function as
% outputs, demote the calcs to private functions called by it

n = size(hbo,2);
for ii=1:n
    tmp = corrcoef(hbo(:,ii), hbr(:,ii));
    c(ii) = tmp(2);
end

pos = find(c==-1);
if ~isempty(pos)
    disp(['Channels with -1 correlation: ' num2str(pos)])
end

pos2 = find(c>0.5);
if ~isempty(pos2)
    disp(['Channels with >0.5 correlation: ' num2str(pos2)])
end

bad = [pos pos2];