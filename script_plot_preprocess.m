% applying the filter/MARA settings to the uncorrected data in spm_fnirs

evt_file = 'NIRS-2017-05-05_001.evt'; % set to '' if you want no event file reading/plotting

% channel to plot
chan2plot = 1;

% load file(s)
load('NIRS.mat');
if ~isempty(evt_file)
    [ons,val] = nirx_read_evt(evt_file);
end

% this part happens in the first level estimation step normally
origY = reshape(spm_vec(rmfield(Y, 'od')), [P.ns P.nch 3]);
newY = spm_fnirs_preproc(origY, P); % uses already estimated params to re-preprocess raw data
clear Y;

% get a time vector
time = 1:P.K.D.ns;
time = time * P.K.D.nfs;

% get uncorrected but resampled data
p = round(10*P.K.D.nfs);
q = round(10*P.fs);
dim = size(origY);
origY = resample(origY, p, q);
dim(1) = P.K.D.ns;
origY = reshape(origY, dim);
if ~isempty(evt_file) % apply resampling to stimulus onsets
    ons = round(ons*p/q);
end

% plot to compare
figure('color','w');
h1=subplot(2,1,1); 
plot(time,squeeze(newY(:,chan2plot,1)),'r'); 
xlabel('Time (s)'); ylabel({'HbO','Concentration'});
hold on;
plot(time,squeeze(origY(:,chan2plot,1)),'b');
plot(time,squeeze(origY(:,chan2plot,1))-squeeze(newY(:,chan2plot,1)),'g');
xlim([h1.XLim(1) time(end)]);
legend({'Corrected','Uncorrected','Uncorrected-Corrected'});
h2=subplot(2,1,2); 
plot(time,squeeze(newY(:,chan2plot,2)),'r'); 
xlabel('Time (s)'); ylabel({'HbR','Concentration'});
hold on;
plot(time,squeeze(origY(:,chan2plot,2)),'b');
plot(time,squeeze(origY(:,chan2plot,2))-squeeze(newY(:,chan2plot,2)),'g');
xlim([h1.XLim(1) time(end)]);
legend({'Corrected','Uncorrected','Uncorrected-Corrected'});

% plot event markers, if desired
if ~isempty(evt_file)
    axes(h1);
    for ii=1:length(ons)
        line([time(ons(ii)) time(ons(ii))], h1.YAxis.Limits, 'color','r',...
            'linestyle','--','linewidth',.25);
        text(time(ons(ii)), h1.YAxis.Limits(2)+.01,num2str(val(ii)),'rotation',90);
    end
    axes(h2);
    for ii=1:length(ons)
        line([time(ons(ii)) time(ons(ii))], h2.YAxis.Limits, 'color','r',...
            'linestyle','--','linewidth',.25);
        %text(time(ons(ii)), h2.YAxis.Limits(2)+.01,num2str(val(ii)),'rotation',90);
    end
end