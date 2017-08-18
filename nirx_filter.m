function fraw = nirx_filter(raw,hdr,type,cutoffs,varargin)
% NAME:      nirx_filter.m
% AUTHOR:    Don Rojas, Ph.D.
% PURPOSE:   a basic filtering function for fnirs timeseries
%            that will provide bandpass filtering of
%            the butterworth type IIR in forward/reverse fashion for zero
%            phase-shift.
% INPUTS:    wl1,wl2 = nirx waveforms, e.g., from nirx_read_wl.m
%            hdr = header from nirx_read_hdr.m
%            cutoffs = [lowcut highcut] in Hz, or single number for low,
%            high and moving filter types. For moving filter, the number is
%            indicates the number of seconds of data averaged
%            type = filter type ('low','high', 'moving' or 'band')
% OPTIONAL:  'order', filter order 3 = default, if type = 'moving', then
%             order is ignored
% OUTPUTS:   fraw = filtered version of data
% USAGE: (1) fraw = nirx_filter(raw,hdr,'band',[.01 .5]);
% NOTES: (1) be careful applying this to data uncritically. If bad results
%            are obtained, can evaluate B,A transfer coefficients using freqs(B,A);
% SEE ALSO: nirx_read_wl.m, nirx_read_hdr.m

% HISTORY: 07/13/16 - first version, based on megcode filterer.m function

% FIXME: check for installation of signal processing toolbox here

% defaults
filtind      = [];
order        = 3;
dB           = .5;
filt         = 'butter';

% parse input and set default options
if nargin < 2
    error('Must supply at least 3 arguments to function!');
else
    if ~isempty(varargin)
        optargin = size(varargin,2);
        if (mod(optargin,2) ~= 0)
            error('Optional arguments must come in option/value pairs');
        else
            for i=1:2:optargin
                switch upper(varargin{i})
                    case 'ORDER'
                        order = varargin{i+1};
                    otherwise
                        error('Invalid option!');
                end
            end
        end
    else
        % do nothing
    end
end

% basic signal info
sr      = hdr.sr;
wl1     = squeeze(raw(1,:,:));
wl2     = squeeze(raw(2,:,:));
nchn    = size(raw,3);
npnts   = size(raw,2);

% create appropriate butterworth filter coefficients
switch type
    case 'low'
        % low pass
        if length(cutoffs) > 1
            error('For high/low pass, enter only one cutoff frequency');
        else
            [B, A] = butter(order, cutoffs/(sr/2), 'low');
        end
    case 'high'
        % butterworth high pass
        if length(cutoffs) > 1
            error('For high/low pass, enter only one cutoff frequency');
        else
            [B, A] = butter(order, cutoffs/(sr/2), 'high');
        end
    case 'band'
        % butterworth characteristic bandpass
        if length(cutoffs) ~= 2
            error('For band pass, enter two frequency cutoffs');
        else
            [B, A] = butter(order, [cutoffs(1) cutoffs(2)]/(sr/2));   
        end
    case 'moving'
        % moving average filter
        if length(cutoffs) > 1
            error('For moving average, enter only one number - number of seconds in average!');
        elseif cutoffs < ceil(hdr.sr)
            error('For moving average, n seconds must be higher than 1');
        else
            B = repmat(1/ceil(hdr.sr*cutoffs),1,ceil(hdr.sr*cutoffs));
            A = 1;
        end
    otherwise
        error('Badly formed input!');
end

B = double(B); 
A = double(A);

% apply filter to data, zero padding to prevent edge problems with moving
% filter
fprintf('\nFiltering channel');
fwl1 = zeros(size(wl1));
fwl2 = fwl1;
pads = zeros(ceil(hdr.sr),nchn);
% padding + offset removal
if strcmpi(type,'moving')
    fwl1 = [pads; fwl1; pads];
    fwl2 = fwl1;
    wl1_mean = mean(wl1);
    wl2_mean = mean(wl2);
    wl1 = [pads; wl1-repmat(wl1_mean,npnts,1); pads];
    wl2 = [pads; wl2-repmat(wl2_mean,npnts,1); pads];
end
for chn = 1:nchn
    fprintf('\nFiltering channel: %d', chn);
    % forward and reverse filter for zero phase-shift
    fwl1(:,chn) = filtfilt(B, A, double(wl1(:,chn)));
    fwl2(:,chn) = filtfilt(B, A, double(wl2(:,chn)));
end
% remove zero padding and add back offset
if strcmpi(type,'moving')
    fwl1 = fwl1(ceil(hdr.sr)+1:ceil(hdr.sr)+npnts,:);
    fwl1 = fwl1 + repmat(wl1_mean,npnts,1);
    fwl2 = fwl2(ceil(hdr.sr)+1:ceil(hdr.sr)+npnts,:);
    fwl2 = fwl2 + repmat(wl2_mean,npnts,1);
end
fprintf('\ndone!\n');

% output
fraw(1,:,:)=fwl1;
fraw(2,:,:)=fwl2;

end