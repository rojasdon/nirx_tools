% load and average nirs-spm waveforms for event related or block average by
% condition

nirs=nirx_read_hdr('BTCtest-2015-02-03_002.hdr');

% establish time pre and post to average around
pre_time = 2; % time in seconds prestim
post_time = 16; % time in seconds poststim
sr = nirs.sr;
pre_samp = round(pre_time/(1/sr));
post_samp = round(post_time/(1/sr));

load('Pong_KB_Hb_preproc.mat');
events = [nirs.events.samp];
nevents = length(events);
data = nirs_data.oxyData;

% extract trial array
trials = zeros(pre_samp+post_samp,nirs.nchan,nevents);
for ii=1:nevents
    trials(:,:,ii) = data(events(ii)-pre_samp:events(ii)+post_samp-1, :);
end

% averages
ga=mean(trials,3);
conditions=unique([nirs.events.code]);
for ii=1:length(conditions)
    ind = find([nirs.events.code] == conditions(ii));
    tmp = trials(:,:,ind);
    sorted{ii} = tmp;
    tmp = mean(tmp,3);
    base = repmat(mean(tmp(1:pre_samp,:)),pre_samp+post_samp,1);
    avg{ii} = tmp - base;
end
