clear all;

% files to read
evt_file = '029-2015-12-05_001.evt';
master_file = 'master_list_thesis_triggers_face_conditions.txt';

% read nirx event file
[onsets,vals]=nirx_read_evt(evt_file);

% read master trig file
fp=fopen(master_file,'r');
Mt=textscan(fp,'%d');
Mt=double(Mt{1});

% count trigs from master file
unique_Mt = unique(Mt);
counts = zeros(15,2);
for ii=1:length(unique_Mt)
    n = length(find(Mt == unique_Mt(ii)));
    counts(ii,1) = n;
end

% define trigger and response values
rest_block_trig = 112;
happy_trial_trig = 16;
angry_trial_trig = 32;
neutral_trial_trig = 48;
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
face_trial_trig = 240;
happy_response_trig = 4;
not_happy_response_trig = 8;

% indices of responses
response_ind = bitand(happy_response_trig+not_happy_response_trig,vals);
n_responses = length(find(response_ind));

% define bit ranges
lower4 = 2^4-1; % lowest 4 bits (these are not used for trigger codes from e-prime)
upper4 = bitshift(lower4,4);

% get vals with lowest 4 bits masked out
eprime_trig_vals = bitand(upper4,vals);
cedrus_trig_vals = bitand(lower4,vals);

% count and report eprime trigs
eprime_unique = unique(eprime_trig_vals);
eprime_unique(1) = []; % get rid of zero
fprintf('Type\tMaster\tEvent\tDifference\n');

for ii=1:length(eprime_unique)
    n = length(find(eprime_trig_vals == eprime_unique(ii)));
    counts(ii,2) = n;
    fprintf('%d\t%d\t%d\t%d\n',unique_Mt(ii),counts(ii,1),counts(ii,2),counts(ii,1)-counts(ii,2));
end
fprintf('\nResponses:\n');

% count and report cedrus trigs
cedrus_unique = unique(cedrus_trig_vals);
cedrus_unique(1) = []; % get rid of zero
for ii=1:length(cedrus_unique)
    n = length(find(cedrus_trig_vals == cedrus_unique(ii)));
    counts(ii,2) = n;
    fprintf('Trig %d: %d\n',cedrus_unique(ii),n);
end

% get rid of block triggers
eprime_trig_vals(eprime_trig_vals == neutral_voice_block_trig) = 0;
eprime_trig_vals(eprime_trig_vals == happy_voice_block_trig) = 0;
eprime_trig_vals(eprime_trig_vals == angry_voice_block_trig) = 0;
eprime_trig_vals(eprime_trig_vals == neutral_block_trig) = 0;
eprime_trig_vals(eprime_trig_vals == happy_block_trig) = 0;
eprime_trig_vals(eprime_trig_vals == angry_block_trig) = 0;
eprime_trig_vals(eprime_trig_vals == rest_block_trig) = 0;
eprime_trig_vals(eprime_trig_vals == face_block_trig) = 0;

% get indices of cleaned triggers
orig_ind = find(eprime_trig_vals);

% moving mode filter approach to further clarify block structure
trigs = eprime_trig_vals(orig_ind);
md = moving(trigs,11,@(trigs)mode(trigs));

% take derivative and use to find onsets
dmd = [0; diff(md)];
dmd = sqrt(dmd.^2);
onsets_ind = [1;find(dmd)];

% plot the blocks and overlay onsets as vertical lines
plot(md,'r'); hold on;
y1 = min(md); y2 = max(md);
for ii=1:length(onsets_ind)
    x = onsets_ind(ii);
    line([x x], [y1 y2],'color','b','linestyle','--');
end

% cast the onsets back to original indices
new_onset_ind = orig_ind(onsets_ind);

% create a figure to double-check originals
figure;
plot(eprime_trig_vals,'b');
hold on;
for ii=1:length(new_onset_ind)
    x = new_onset_ind(ii);
    line([x x], [y1 y2],'color','r','linestyle','--');
end

% write these new onsets to file
newvals   = md(onsets_ind);
newonsets = onsets(new_onset_ind);
nirx_write_evt(out_file,newonsets,newvals);