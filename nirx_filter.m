function fdata = nirx_filter(data,hdr,type,cutoffs,varargin)
% NAME:      nirx_filter.m
% AUTHOR:    Don Rojas, Ph.D.
% PURPOSE:   a basic filtering function for fnirs timeseries
%            that will provide bandpass filtering of
%            the butterworth type IIR in forward/reverse fashion for zero
%            phase-shift.
% INPUTS:    data = N channel x N timepoint waveforms, e.g., from nirx_read_wl.m
%            hdr = header from nirx_read_hdr.m
% OPTIONAL:  cutoffs = [lowcut highcut] in Hz, or single number for low,
%            high and moving filter types. For moving filter, the number is
%            indicates the number of seconds of data averaged
%            type = filter type ('low','high', 'moving' or 'band')
%            coeff = filter coefficients [B,A], if supplied cutoffs and
%            type ignored
% OPTIONAL:  'order', filter order 3 = default, if type = 'moving', then
%             order is ignored
% OUTPUTS:   fdata = filtered version of data
% USAGE: (1) fhbo = nirx_filter(hbo,hdr,'low',.4,'order',4);
% NOTES: (1) be careful applying this to data uncritically. If bad results
%            are obtained, can evaluate B,A transfer coefficients using freqs(B,A);
% SEE ALSO: nirx_read_wl.m, nirx_read_hdr.m

% HISTORY: 07/13/16 - first version, based on megcode filterer.m function
%          03/03/22 - updated to take data more generically, rather than
%                     only raw wl data
%          07/22/24 - changed default order to 2 from 3
%          04/14/25 - added option to feed filter coefficients (b,a)
%                     directly to function, bypassing calculation within
%                     function (useful for gui fnirs_filter interface

% FIXME: check for installation of signal processing toolbox here

% defaults
order       = 2;
coeffs      = [];

% parse input and set default options
if nargin < 2
    error('Must supply at least 3 arguments to function!');
else
    if ~isempty(varargin)
        optargin = size(varargin,2);
        if (mod(optargin,2) ~= 0)
            error('Optional arguments must come in option/value pairs');
        else
            for option=1:2:optargin
                switch upper(varargin{option})
                    case 'TYPE'
                        cutoffs = varargin{option+1};
                    case 'CUTOFFS'
                        cutoffs = varargin{option+1};
                    case 'ORDER'
                        order = varargin{option+1};
                    case 'COEFF'
                        coeffs = varargin{option+1};
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
nchn    = size(data,1);
npnts   = size(data,2);

% apply coefficients if supplied, or calculate them if not
if ~isempty(coeffs)
    B = coeffs(1);
    A = coeffs(2);
else
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
                [B, A] = butter(order, [cutoffs(1) cutoffs(2)]/(sr/2),'bandpass');   
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
end

B = double(B); % make sure the type is double
A = double(A);

% apply filter to data
fdata = zeros(size(data));
fprintf('\nFiltering channel');
for chn = 1:nchn
    fprintf('\nFiltering channel: %d', chn);
    % forward and reverse filter for zero phase-shift
    fdata(chn,:) = filtfilt(B, A, double(data(chn,:)));
end
fprintf('\ndone!\n');