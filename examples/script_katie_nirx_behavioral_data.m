% script that aggregates behavioral responses from NIRx evt file
clear all;

% defaults to change
evt_file = '005-2015-11-12_001.evt';
master_file = 'master_list_thesis_triggers_face_conditions.txt';
tmax = 2; % time in s max response
sr = 1/3.9062; % sampling rate

% read nirx event file
[onsets,vals]=nirx_read_evt(evt_file);

% read master trig file
Mt=csvread(master_file);
triggers = Mt(:,1);
conditions = Mt(:,2);

% define trigger and response values
rest_block_trig = 112;
happy_trial_trig = 16; %
angry_trial_trig = 32; %
neutral_trial_trig = 48; %
happy_block_trig = 64;
angry_block_trig = 80;
neutral_block_trig = 96;
happy_voice_trial_trig = 128;
angry_voice_trial_trig = 144;
neutral_voice_trial_trig = 160;
happy_voice_block_trig = 176;
angry_voice_block_trig = 192;
neutral_voice_block_trig = 208;
face_block_trig = 224;
face_trial_trig = 240; %
happy_response_trig = 4;
not_happy_response_trig = 8;
trigs_that_matter = sort([angry_trial_trig happy_trial_trig neutral_trial_trig face_trial_trig]);

% count trigs and conditions from master file
unique_trigs = unique(triggers);
counts = zeros(length(unique_trigs));
for ii=1:length(unique_trigs)
    n = length(find(triggers == unique_trigs(ii)));
    counts(ii) = n;
    fprintf('Trigger %d n: %d\n',unique_trigs(ii),n);
end
unique_conditions = unique(conditions);
counts = zeros(length(unique_conditions));
for ii=1:length(unique_conditions)
    n = length(find(conditions == unique_conditions(ii)));
    counts(ii) = n;
    fprintf('Condition %d n: %d\n',unique_conditions(ii),n);
end
counts = zeros(1,length(unique_conditions)*length(unique(trigs_that_matter)));
for ii=1:length(trigs_that_matter)
    for jj=1:length(unique_conditions)
        [~,index] = ismember(Mt,[trigs_that_matter(ii) unique_conditions(jj)],'rows');
        n = length(find(index));
        counts(ii*jj) = n;
        fprintf('Trigger %d, Condition %d : %d\n',trigs_that_matter(ii), unique_conditions(jj),n);
    end
end
fprintf('Sum of trigger*condition counts: %d\n',sum(counts));

% define bit ranges
lower4 = 2^4-1; % lowest 4 bits (these are not used for trigger codes from e-prime)
upper4 = bitshift(lower4,4);

% get vals with lowest 4 bits masked out
eprime_trig_vals = bitand(upper4,vals)';
cedrus_trig_vals = bitand(lower4,vals)';
cedrus_trig_vals = bitand(12,cedrus_trig_vals);

% indices of unwanted triggers like block triggers
unwanted = [rest_block_trig happy_block_trig neutral_block_trig angry_block_trig happy_voice_block_trig ...
            neutral_voice_block_trig angry_voice_block_trig face_block_trig];
for ii=1:length(unwanted)
    unwanted_ind = sort(find(eprime_trig_vals == unwanted(ii)));
    eprime_trig_vals(unwanted_ind) = 0;
end

% indices of responses
response_sum = happy_response_trig+not_happy_response_trig;
clean_responses = bitand(response_sum,cedrus_trig_vals);
response_ind = find(clean_responses);
n_responses = length(response_ind);

% combine clean response and trig, remove unwanted combos such as responses
% to voice only trials, remove responses simultaneous with trigs because it
% looks like they are doubled from prior stimulus
for ii=1:length(eprime_trig_vals)
    if eprime_trig_vals(ii) > 0 && clean_responses(ii) > 0
        clean_responses(ii) = 0;
    end
end     
combined_bits = clean_responses+eprime_trig_vals;
unwanted_combos = [[happy_voice_trial_trig happy_response_trig]; ...
                   [happy_voice_trial_trig not_happy_response_trig]; ...
                   [neutral_voice_trial_trig happy_response_trig]; ...
                   [neutral_voice_trial_trig not_happy_response_trig]; ...
                   [angry_voice_trial_trig happy_response_trig]; ...
                   [angry_voice_trial_trig not_happy_response_trig]];
for ii=1:size(unwanted_combos,1)
    ind = strfind(combined_bits,unwanted_combos(ii,:));
    combined_bits(ind:ind+1) = 0;
end

% eliminate unwanted double responses, leaving only first one
unwanted_doubles = [[happy_response_trig happy_response_trig]; ...
                    [happy_response_trig not_happy_response_trig]; ...
                    [not_happy_response_trig happy_response_trig]; ...
                    [not_happy_response_trig not_happy_response_trig]];
for ii=1:size(unwanted_doubles,1)
    ind = strfind(combined_bits,unwanted_doubles(ii,:));
    combined_bits(ind+1) = 0;
end

% finally, clean out 0 data in combined_bits
combined_bits(combined_bits == 0) = [];

% use strfind to get the combinations e.g., strfind(combined_bits,[240 4])
% returns happy response to face trials
face_only_happy = strfind(combined_bits,[face_trial_trig happy_response_trig]);
neutral_voice_happy = strfind(combined_bits,[neutral_trial_trig happy_response_trig]);
angry_voice_happy = strfind(combined_bits,[angry_trial_trig happy_response_trig]);
happy_voice_happy = strfind(combined_bits,[happy_trial_trig happy_response_trig]);
face_only_not = strfind(combined_bits,[face_trial_trig not_happy_response_trig]);
neutral_voice_not = strfind(combined_bits,[neutral_trial_trig not_happy_response_trig]);
angry_voice_not = strfind(combined_bits,[angry_trial_trig not_happy_response_trig]);
happy_voice_not = strfind(combined_bits,[happy_trial_trig not_happy_response_trig]);
all_face_only = sort([face_only_happy face_only_not]);
all_neutral_voice = sort([neutral_voice_happy neutral_voice_not]);
all_angry_voice = sort([angry_voice_happy angry_voice_not]);
all_happy_voice = sort([happy_voice_happy happy_voice_not]);


% reaction times (can only be as accurate as 1/sr in sec)
rt_happy = (1 + fix(onsets(happy_voice_happy + 1) - onsets(happy_voice_happy)) * sr) - sr;
rt_angry = (1 + fix(onsets(angry_voice_happy + 1) - onsets(angry_voice_happy)) * sr) - sr;
rt_neutral = (1 + fix(onsets(neutral_voice_happy + 1) - onsets(neutral_voice_happy)) * sr) - sr;
rt_face_only = (1 + fix(onsets(face_only_happy + 1) - onsets(face_only_happy)) * sr) - sr;
rt_all_face_only = (1 + fix(onsets(all_face_only + 1) - onsets(all_face_only)) * sr) - sr;
rt_all_neutral = (1 + fix(onsets(all_neutral_voice + 1) - onsets(all_neutral_voice)) * sr) - sr;
rt_all_happy = (1 + fix(onsets(all_happy_voice + 1) - onsets(all_happy_voice)) * sr) - sr;
rt_all_angry = (1 + fix(onsets(all_angry_voice + 1) - onsets(all_angry_voice)) * sr) - sr;
rt_face_not = (1 + fix(onsets(face_only_not + 1) - onsets(face_only_not)) * sr) - sr;
rt_neutral_not = (1 + fix(onsets(neutral_voice_not + 1) - onsets(neutral_voice_not)) * sr) - sr;
rt_angry_not = (1 + fix(onsets(angry_voice_not + 1) - onsets(angry_voice_not)) * sr) - sr;
rt_happy_not = (1 + fix(onsets(happy_voice_not + 1) - onsets(happy_voice_not)) * sr) - sr;
rt_happy(rt_happy > tmax) = [];
rt_angry(rt_angry > tmax) = [];
rt_neutral(rt_neutral > tmax) = [];
rt_face_only(rt_face_only > tmax) = [];
rt_happy_not(rt_happy_not > tmax) = [];
rt_angry_not(rt_angry_not > tmax) = [];
rt_neutral_not(rt_neutral_not > tmax) = [];
rt_face_not(rt_face_not > tmax) = [];
rt_all_face_only(rt_all_face_only > tmax) = [];
rt_all_neutral(rt_all_neutral > tmax) = [];
rt_all_angry(rt_all_angry > tmax) = [];
rt_all_happy(rt_all_happy > tmax) = [];

% sort these face/response pairs into condition bins - have to figure out
% how to align triggers from file with triggers in vals...take first n
% trials? Won't matter for behavioral data, but would not allow alignement
% for trial by trial regressor. That might not be possible anyway because
% there are not 140 triggers per condition in evt file
voice_cond_names = {'happy','neutral','angry','face'};
nconditions = length(unique(conditions)) - 1;
voice_cond_trig = [16 48 32 240];
perc_happy_resp = zeros(4,7);
for ii=1:length(voice_cond_names)
    trig_ind = find(triggers == voice_cond_trig(ii));
    % choose trials one by one from NIRx timeline, assuming condition from
    % the master list file
    switch voice_cond_names{ii}
        case 'happy'
            onsets = all_happy_voice;
        case 'angry'
            onsets = all_angry_voice;
        case 'neutral'
            onsets = all_neutral_voice;
        case 'face'
            onsets = all_face_only;
    end
    cond_num = conditions(trig_ind);
    condition_sums = cell(7,1);
    for jj=1:length(trig_ind)
        % find next trigger face+voice match in combined bits
        if jj > numel(onsets)
            break;
        end
        tmp = combined_bits(onsets(jj)+1); % response is +1 from onset trig
        switch tmp
            case 4
                resp = 1;
            case 8
                resp = 0; % redundant, but might be useful for rerun sometime
            otherwise
                resp = 0;
        end
        condition_sums{cond_num(jj)} = [condition_sums{cond_num(jj)} resp];
    end
    for jj=1:nconditions
        perc_happy_resp(ii,jj) = sum(condition_sums{jj})/length(condition_sums{jj});
    end
end

% get indices of cleaned triggers
orig_ind = find(eprime_trig_vals);

% cast the onsets back to original indices
% new_onset_ind = orig_ind(onsets_ind);