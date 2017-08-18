% script to produce synthesis of Everden Stop Signal Task behavioral output
% and NIRx system received optical triggers

% PROBLEM THIS SCRIPT RESOLVES: SST does not put out trigger codes, so we
% used optical trigger for all visual stimuli to signal trial onset, but we
% do not have proper condition coding. Evenden's task puts out a file of
% behavior and trial type, so this script reads that file, and attempts to
% code the NIRx events by spreadsheet coding if possible.

% ASSUMPTION: No missing triggers, since a missing trigger at beginning or
% anywhere else would cause systematic misalignment between two files.
% Basic checking for this only (e.g, count number of events in files to see
% if they match).

% VARIABLES TO CHANGE HERE IF NEEDED
participant_no = 8;
xls_to_read = 'pilot_data_008.xls';
evt_to_read = 'btc_008_stopsig.evt';
correct_file = 'Trial_Responses_StopSig.mat'; % use this for regressors in 1st level if desired
[p, base, ext] = fileparts(evt_to_read);
evt_rename = [base '_orig' ext];
go_code = '1\t0\t0\t0\t0\t0\t0\t0\n'; % 1 in NIRx
% go_incorrect_code = '0\t1\t0\t0\t0\t0\t0\t0\n'; % 2
stop_code = '0\t1\t0\t0\t0\t0\t0\t0\n'; % 2
% stop_incorrect_code = '0\t0\t0\t1\t0\t0\t0\t0\n'; % 8

% DEFAULTS (CHANGE ONLY IF YOU KNOW WHAT YOU'RE DOING)
worksheet_name = 'SST_trial';
id_column = 3;
correct_column = 7;
incorrect_column = 8;
rt_column = 9;
trial_type = 5;

% READ SPREADSHEET AND GET SOME INFO
WS = xlsread(xls_to_read,worksheet_name);
trial_ind = find(WS(:,id_column) == participant_no);
WS = WS(trial_ind,:);
Nt = size(WS,1);
corr_ind = find(WS(:,correct_column) == 1);
incorr_ind = find(WS(:,incorrect_column) == 1);
Nc = length(corr_ind);
Ni = length(incorr_ind);
RTc = mean(WS(corr_ind,rt_column));
RTi = mean(WS(incorr_ind,rt_column));
go_ind = find(WS(:,trial_type) == 0);
stop_ind = find(WS(:,trial_type) ~= 0);
% Q for J. Evenden: is -99 a non-response?

% DISPLAY BASIC INFO ABOUT RUN
fprintf('N Trials: %d\n', Nt);
fprintf('N Stop Trials: %d\n', length(stop_ind));
fprintf('N Correct: %d\n', Nc);
fprintf('N Incorrect: %d\n', Ni);
fprintf('RT Correct: %.2f\n', RTc);
fprintf('RT Incorrect: %.2f\n', RTi);

% READ EVT FILE 
[onsets,vals] = nirx_read_evt(evt_to_read);

% WRITE NEW EVT FILE, FIRST MAKING COPY OF OLD ONE
movefile(evt_to_read,evt_rename);
fp = fopen(evt_to_read,'w');
for ii=1:Nt
    if ismember(ii,go_ind)
        fprintf(fp,['%s\t' go_code],num2str(onsets(ii)));
    else
        fprintf(fp,['%s\t' stop_code],num2str(onsets(ii)));
    end
end

% SAVE A MAT FILE WITH A VECTOR OF CORRECT/INCORRECT FOR 1st LEV STATS
% (1=correct)
resp_vec = zeros(1,Nt);
resp_vec(corr_ind) = 1;
save(correct_file,'resp_vec');

fclose(fp);