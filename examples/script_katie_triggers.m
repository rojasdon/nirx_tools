clear all;
file = 'Katie.evt';
rest_block = 112;
happy_block = [];
angry_block = [];
neutral_block = [];
happy_trial = 16;
happy_response = 4;
not_happy_response = 8;
[onsets,vals]=nirx_read_evt(file);
responses = bitand(12,vals);
n_responses = length(find(responses));
no_audio_or_response=vals-bitand(14,vals);
n_audio_only = length(find(no_audio_or_response == 0));
n_rest=length(find(no_audio_or_response == rest_block));
n_happy_trials=length(find(no_audio_or_response == happy_trial));
n_happy_responses = length(find(responses == happy_response));
n_triggers = length(vals);
codes_used = unique(no_audio_or_response(find(no_audio_or_response)));

% count all non-audio and non-response code triggers
counts = [];
for ii=1:length(codes_used)
    tmp = find(no_audio_or_response == codes_used(ii));
    counts(ii)=length(tmp);
    event_list{ii}.onsets = onsets(tmp);
    event_list{ii}.values = no_audio_or_response(tmp);
    fprintf('Code %d: %d\n',codes_used(ii),counts(ii));
end

% count response codes and make event lists by type
r_counts = [];
r_codes = [4 8];
event_lists = {};
for ii=1:length(r_codes)
    r_counts(ii)=length(find(responses == r_codes(ii)));
    fprintf('Response Code %d: %d\n',r_codes(ii),r_counts(ii));
end


% find repeats
Y=diff(onsets);
ind=find(Y==0)+1;
repeats=no_audio_or_response(ind);
fprintf('# of repeats: %d\n', length(repeats));