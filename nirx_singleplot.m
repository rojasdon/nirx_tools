function h = nirx_singleplot(hdr,data,chan,wsel,varargin)
% function to plot single channel data
% inputs:
%   1. hdr = header structure from nirx_read_hdr
%   2. data = 2 x npoint x nchan array from nirx_read_wl
%   3. chan = channel within array to plot
%   4. wsel = 1 = 'wl1' or 2 = 'wl2'
% optional input in opt/arg pairs:
%   1. 'plotevt','file' = plot evt events on timeline, name of file

% parse options
plotevt = 0;
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
                    case 'PLOTEVT'
                        plotevt = 1;
                        file = varargin{ii+1};
                    otherwise
                        error('Invalid or unrecognized option!');
                end
            end
        end
    else
        % do nothing
    end
end

% basic info
fs = 1/hdr.sr;
nsamp = size(data,2);
time = (1:double(nsamp))*fs;

% set up figure
h=figure('color','w');
chndat = squeeze(data(wsel,:,chan));

% optionally plot event marks
yl = zeros(1,2);
if plotevt
    yl(1) = min(chndat);
    yl(2) = max(chndat);
    hold on; axis tight;
    [onsets,vals]=nirx_read_evt(file);
    onsets = onsets * fs;
    uval = unique(vals);
    colors = [0 0 0
              1 0 0
              0 1 0
              0 0 1
              1 1 0
              0 1 1
              1 0 1
              .5 .5 .5
              .5 .5 1
              1 .5 .5
              .5 1 .5
              .8 .2 .1
              .1 .2 .8];
    for ii=1:length(uval)
        ind = find(vals == uval(ii));
        for jj=1:length(onsets(ind))
            line([onsets(ind(jj)),onsets(ind(jj))],[yl(1),yl(2)],'linestyle','--','color',colors(ii,:));
        end
    end
end

% plot data
plot(time,chndat,'linewidth',2,'color','b');
xlabel('Time (s)');
ylabel('Optical Density');

end