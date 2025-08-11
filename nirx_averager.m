% PURPOSE:  provides averages of conditions repeated in experiment
% AUTHOR:   D. Rojas
% INPUTS:   hdr, from nirx_read_hdr
%           od, optical data nchan x npoints
%           win, epoch window, in seconds (e.g., [-5 20])
%           onsets, vector of onsets in samples from nirx_read_evt
%           vals, vector of values from nirx_read_evt
%           type, integer type of condition to average
% HISTORY: 08/06/2025 - bugfix to time output
function [av,t] = nirx_averager(hdr,od,win,onsets,vals,type)

% units and time
int   = 1/hdr.sr;   % interval per sample, in sec
pstim = abs(win(1)); 
t0 = abs(win(1));
t1 = abs(win(2));
t0 = round(t0/int); % in samples
t1  = round(t1/int);
ep_samples = abs(t0)+abs(t1);
t = (1:double(ep_samples))*int;
t = (t -(abs(pstim)));

% find the events and limit to type desired
onsets = onsets(vals == type);

% extract epochs
epochs     = zeros(length(onsets),size(od,1),ep_samples);
skipped    = [];
fprintf('\nExtracting epochs\n');
for ii=1:length(onsets)
    if onsets(ii)-t0 == abs(onsets(ii)-t0) && ...
            onsets(ii)+t1-1 < size(od,2) && ...
            onsets(ii)-t0 > 0
        fprintf('Epoch: %d\n',ii);
        epochs(ii,:,:) = od(:,onsets(ii)-t0:onsets(ii)+t1-1);
    else
        skipped = [skipped ii];
    end
end

% average and baseline correction
av = squeeze(mean(epochs));
t0 = 1; % first sample of baseline
t1 = get_time_index(t,0); % last sample of baseline
m_base = mean(av(:,t0:t1),2);
av = av - repmat(m_base,1,length(ep_samples));

