function [wl1raw, wl2raw] = nirx_interpolate_chans(basename,posfile,varargin)
% Description:
%   function that uses nearest neighbor interpolation to replace bad channel
%   data in nirx format files
% Required Input:
%   basename = input filename w/o extension
%   posfile = optode position file name e.g., optode_positions.csv
% Optional Inputs in option/arg pairs (must be at least one pair):
%   'threshold', threshold =  gain threshold to find bad chans, or 
%   'channel', channel(s) =  list of channels to interpolate
%   'source', source(s) = list of sources to determine channels
%   'detector', detector(s) = list of detectors to determine channels
% Outputs:
%   wl1raw, wl2raw = corrected wavelength data
% Example 1:
%   [w1,w2]=nirx_interpolate_chans('filebasename','optode_positions.csv', 'threshold', 7);
%   will interpolate based on a threshold of 7
% Example 2:
%   [~,~]=nirx_interpolate_chans('filebasename','optode_positions.csv', 'channels', [3,10]);
%   will interpolate channels (NOT OPTODES!) 3 and 10 and suppress output
%   to workspace
% Example 3:
%   [~,~]=nirx_interpolate_chans('filebasename','optode_positions.csv',
%   'source', 3:4); will interpolate any channels formed with sources 3
%   or 4

% History
% 7/9/16 - first version allowing channel or threshold interpolation

% FIXME: 1. allow both channel and threshold based interp in one call,
%           order of ops should be channel first, mark bad, then gain
%        2. all or mask option for interpolation?
%        3. channels from optodes option
%        4. increase bias to nearer channels?

% parse input and set default options
Sb = [];
Db = [];
if nargin < 4
    error('Must supply at least 4 arguments to function, perhaps you left out the method pair?');
else
    if ~isempty(varargin)
        optargin = size(varargin,2);
        if (mod(optargin,2) ~= 0)
            error('Optional arguments must come in option/value pairs');
        else
            for ii=1:2:optargin
                switch upper(varargin{ii})
                    case 'THRESHOLD'
                        threshold  = varargin{ii+1};
                        method = 'threshold';
                        suffix = '_gint';
                    case 'CHANNEL'
                        channels = varargin{ii+1};
                        method = 'channel';
                        suffix = '_cint';
                    case 'SOURCE'
                        method = 'optode';
                        Sb = varargin{ii+1};
                        suffix = '_cint';
                    case 'DETECTOR'
                        method = 'optode';
                        Db = varargin{ii+1};
                        suffix = '_cint'; 
                    otherwise
                        error('Invalid or unrecognized option!');
                end
            end
        end
    else
        % do nothing
    end
end

% preamble
fprintf('Using nearest neighbor interpolation to repair channels\n');
if strcmpi(method,'threshold')
    fprintf('Threshold for bad channels = %d\n', threshold);
elseif strcmpi(method,'channel')
    fprintf('Channels specified for interpolation:\n');
    for ii = 1:length(channels)
        fprintf('%d, ', channels(ii));
    end
    fprintf('\n');
end
        
% get header info
hdr=nirx_read_hdr([basename '.hdr']);

% import raw data without masking
[raw, cols, ~,~]=nirx_read_wl(basename,hdr,'all');

% find bad channels
cind = find(hdr.SDmask);
chans = hdr.SDpairs;
bind = [];
badchans = [];
if strcmpi(method,'threshold')
    gain = hdr.gains;
    bind = find(gain(cind) > threshold);
    badgains = zeros(size(gain));
    badgains(cind(bind)) = 1;
    [Sb, Db] = ind2sub(size(gain),find(badgains));
    badchans = [Sb Db];
elseif strcmpi(method,'channel') % channels based on provided list
    for ii=1:length(channels)
        badchans = [badchans; chans(channels(ii),:)];
    end
elseif strcmpi(method,'optode')
    for ii=1:length(Sb)
        tmp = find(chans(:,1)==Sb(ii));
        badchans = [badchans; chans(tmp(ii),:)];
    end
    for ii=1:length(Db)
        tmp = find(chans(:,2)==Db(ii));
        badchans = [badchans; chans(tmp(ii),:)];
    end
end

% find their original raw data indices in data from S D indices
chanind = [];
for ii=1:size(badchans,1)
    [~, tmp] = ismember(badchans(ii,:),chans,'rows');
    chanind = [chanind tmp(1)];
end

% construct an array of weights for use in multiplying with data
% restrict it to ones in the mask
[~,ids, pos] = nirx_read_chpos(posfile);
chanpos = nirx_compute_chanlocs(ids,pos,[(1:length(hdr.SDpairs))' hdr.SDpairs]);
nb = nirx_nearest_neighbors(chanpos); % chan distances

% repair the channels in the subgroup used in the mask
maskraw = raw(:,:,cols);
wl1raw  = squeeze(maskraw(1,:,:));
wl2raw  = squeeze(maskraw(2,:,:));
clear maskraw;
for ii=1:length(chanind)
    fprintf('%d: Repairing channel S%d-D%d...\n',ii, badchans(ii,1),badchans(ii,2));
    weights = 1./nb(chanind(ii),:);
    weights(weights == inf) = 0;
    weights(chanind) = 0; % don't use bad channels in weights
    weights = weights ./ sum(weights); % weights sum to 1
    wl1raw(:,chanind(ii)) = wl1raw * weights';
    wl2raw(:,chanind(ii)) = wl2raw * weights';
end

% put the repaired data back into original column locations
% cols are indices into full raw data, so cols(chanind)
raw(1,:,cols(chanind)) = wl1raw(:,chanind);
raw(2,:,cols(chanind)) = wl2raw(:,chanind);

% write the corrected wl* data to files
nirx_write_wl([basename suffix],raw);

% write new header (not modified, but nice to have one w/ same name)
nirx_write_hdr([basename suffix '.hdr'],hdr);

end

