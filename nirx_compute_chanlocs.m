function [longpos,shortpos] = nirx_compute_chanlocs(ids,pos,chns,short_indices)
% function computes midpoints between two optodes 
% as channel locations.
% INPUTS:
% ids = 1 x n array of generic optode labels, S1...Sn, D1...Dn
% pos = n x 3 array of positions
% chns = n x 2 array of channel definitions
% short_indices = 1 x n array of short detector indices from
%   nirx_read_hdr.m
% OUTPUTS:
% longpos = n x 3 array of long channel locations
% shortpos = same as longpos, but short channels

% NOTE: the midpoint on a straight line isn't accurate given that the
% points lie on a surface. Some/many will be inside the head.

% Revision history
% 03/01/2022 - fixed short indexing bug, returns short channel positions
%   separately from longpos

% first sort sensors and detectors
sind = [];
snum = [];
ldind = [];
ldnum = [];
sdind = [];
sdnum = [];
for ii=1:length(ids)
    if ids{ii}{1}(1)=='S'
        sind = [sind ii];
        snum = [snum str2double(ids{ii}{1}(2:end))];
    elseif ids{ii}{1}(1)=='D'
        if ~isempty(find(ismember(short_indices,...
                str2double(ids{ii}{1}(2:end)))))
            sdind = [sdind ii];
            sdnum = [sdnum str2double(ids{ii}{1}(2:end))];
        else
            ldind = [ldind ii];
            ldnum = [ldnum str2double(ids{ii}{1}(2:end))];
        end
    end
end
Spos = pos(sind,:);
Dpos = pos(ldind,:);
SDpos = pos(sdind,:);
clear pos;

% now find midpoint locations for the long channels
short_chan_indices = find(ismember(chns(:,3),short_indices));
chns(short_chan_indices,:) = [];
nchan = length(chns);
longpos = zeros(nchan,3);
for ii = 1:nchan
    if ismember(sdnum,chns(ii,3))
        break;
    else
        chpair = chns(ii,2:3);
        source_ind = find(ismember(snum,chpair(1)));
        det_ind = find(ismember(ldnum,chpair(2)));
        Sloc = Spos(source_ind,:);
        Dloc = Dpos(det_ind,:);
        longpos(ii,1) = (Sloc(1) + Dloc(1))/2;
        longpos(ii,2) = (Sloc(2) + Dloc(2))/2;
        longpos(ii,3) = (Sloc(3) + Dloc(3))/2;
    end
end

% short channels
shortpos = SDpos; % just use the detector location