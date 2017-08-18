% script to produce synthesis of Everden Dot Probe Task behavioral output
% and NIRx system received optical triggers

% PROBLEMS THIS SCRIPT RESOLVES: DOTP does not put out trigger codes, so we
% used optical trigger for all visual stimuli to signal trial onset, but we
% do not have proper condition coding. Evenden's task puts out a file of
% behavior and trial type, so this script reads that file, and attempts to
% code the NIRx events by spreadsheet coding if possible.

% ASSUMPTION: No missing triggers, since a missing trigger at beginning or
% anywhere else would cause systematic misalignment between two files.
% Basic checking for this only (e.g, count number of events in files to see
% if they match).

% DO THIS FIRST - Because Matlab does not support reading Unicode text
% formatting from Excel, and John's file has that coding for the trial
% data, save the Excel worksheet with the DOTP data as a CSV file first.

% VARIABLES TO CHANGE HERE IF NEEDED
participant_no = 7; 
participant_exp = [',' num2str(participant_no) ','];
csv_to_read = 'pilot_data_008_dotp.csv';
evt_to_read = 'btc_008_dotp.evt';
[p, base, ext] = fileparts(evt_to_read);
evt_rename = [base '_orig' ext];
sensation_ccode = '1\t0\t0\t0\t0\t0\t0\t0\n'; % 1 in NIRx, for evt
sensation_iccode = '0\t1\t0\t0\t0\t0\t0\t0\n'; % 2
action_ccode = '1\t1\t0\t0\t0\t0\t0\t0\n'; % 3
action_iccode = '0\t0\t1\t1\t0\t0\t0\t0\n'; % 4
control_ccode = '1\t0\t1\t0\t0\t0\t0\t0\n'; % 5
control_iccode = '0\t1\t1\t0\t0\t0\t0\t0\n'; % 6
key_vals = {'action','sensation','people','neutral'}; % 1-4 in key code, 0 irrelevant b/c training
key_type = {'congruent','incongruent'}; %1-2 in key code

% DEFAULTS (CHANGE ONLY IF YOU KNOW WHAT YOU'RE DOING)
id_column = 3;
data_column = 4;

% READ EVT FILE 
[onsets,vals] = nirx_read_evt(evt_to_read);

% READ CSV FILE AND GET SOME INFO
fid=fopen(csv_to_read,'r');
A=textscan(fid,'%s','Delimiter', '.');
B=strrep(strrep(A{1},'"',''),' ','');
subj_cells = regexp(B,participant_exp,'match');
subj_ind = find(~cellfun(@isempty,subj_cells)); % find indices of subject's data
fclose(fid);
Nt = length(subj_ind);
B = B(subj_ind); % limit array to just subject's data
lr = zeros(1,Nt);
type = zeros(1,Nt);
value = zeros(1,Nt);
rloc = zeros(1,Nt);
rt = zeros(1,Nt);
correct = zeros(1,Nt);
for ii=1:Nt
    tmp = strsplit(char(B{ii}),',');
    nfields = num2str(length(tmp));
    switch nfields
        case {'12','13'} % normal trial
            lr(ii) = str2num(tmp{5});
            type(ii) = str2num(tmp{6});
            value(ii) = str2num(tmp{7});
            if strcmp(tmp{8},'1')
                correct(ii) = 1;
            end
            rloc(ii) = str2num(tmp{10});
            rt(ii) = str2num(tmp{11});
        case '7' % undefined trial
            % do nothing?
        otherwise
            % not a recognized event
    end
end    
% Q for J. Evenden: what does undefined mean in trial data columnn 
sensation_cind = [];
action_cind = [];
control_cind = [];
sensation_ic = [];
action_icind = [];
control_icind = [];
for ii=1:length(key_vals)
    vind = find(value == ii);
    for jj=1:length(vind)
        switch key_vals{ii}
            case 'action'
                if type(vind(jj)) == 1
                    action_cind = [action_cind vind(jj)];
                elseif type(vind(jj)) == 2
                    action_icind = [action_icind vind(jj)];
                end
            case 'sensation'
                if type(vind(jj)) == 1
                    sensation_cind = [sensation_cind vind(jj)];
                elseif type(vind(jj)) == 2
                    sensation_icind = [sensation_icind vind(jj)];
                end
            case 'people'
                if type(vind(jj)) == 1
                    control_cind = [control_cind vind(jj)];
                elseif type(vind(jj)) == 2
                    control_icind = [control_icind vind(jj)];
                end
            otherwise
                % do nothing here for now, maybe integrate neutrals = 4
                % later?
        end
    end
end

% WRITE NEW EVT FILE, FIRST MAKING COPY OF OLD ONE
movefile(evt_to_read,evt_rename);
fp = fopen(evt_to_read,'w');
action_cn = 1;
action_icn = 1;
sensation_cn = 1;
sensation_icn = 1;
control_cn = 1;
control_icn = 1;
for ii=1:length(vals)
    switch vals(ii)
        case 1
            if type(ii) == 1
                fprintf(fp,['%s\t' action_ccode],num2str(onsets(ii)));
            else
                fprintf(fp,['%s\t' action_iccode],num2str(onsets(ii)));
            end
        case 2
            if type(ii) == 1
                fprintf(fp,['%s\t' sensation_ccode],num2str(onsets(ii)));
            else
                fprintf(fp,['%s\t' sensation_iccode],num2str(onsets(ii)));
            end
        case 3
            if type(ii) == 1
                fprintf(fp,['%s\t' control_ccode],num2str(onsets(ii)));
            else
                fprintf(fp,['%s\t' control_iccode], num2str(onsets(ii)));
            end
        otherwise
            % nothing
    end
end
% DISPLAY BASIC INFO ABOUT RUN
fprintf('N Trials: %d\n', Nt);
fprintf('N Correct: %d\n', sum(correct));
fprintf('N Incorrect: %d\n', Nt-sum(correct));
fprintf('N Sensation congruent trials: %d\n', numel(sensation_cind));
fprintf('N Sensation incongruent trials: %d\n', numel(sensation_icind));
fprintf('N Action congruent trials: %d\n', numel(action_cind));
fprintf('N Action incongruent trials: %d\n', numel(action_icind));
fprintf('N Control congruent trials: %d\n', numel(control_cind));
fprintf('N Control incongruent trials: %d\n', numel(control_icind));

fclose(fp);