% script to create F tests between two groups of time-frequency
% results. The F test is conducted at every time-frequency bin.

% options
ngroups     = 3; % groups = levels for rm design
fname       = 'nepower'; % the name of the field in the tf structure you want to test
filemask    = {'*_l32_tft.mat','*_l40_tft.mat','*_l48_tft.mat'};
tails       = 2; % tails on F-test
sphericity  = 0; % 0 to assume sphericity, 1 to apply Greenhouse-Geisser

% structure to contain group file names and identities
groups       = [];
groups.id    = [];
groups.files = {};
groups.paths = {};
N            = zeros(1,ngroups);

% get file names and paths for groups
for i=1:ngroups
    [filelist path]  = uigetfile(filemask{i},'MultiSelect','on',['Select level ' num2str(i)]);
    N(i)             = length(filelist);
    groups.files     = [groups.files [filelist]];
    groups.id        = [groups.id ones(1,N)*i];
    tmp              = cell(1,N);
    [tmp{:}]         = deal(path);
    groups.paths     = [groups.paths [tmp]];
end

% make sure all levels have same number of subjects!
if sum(N - mean(N)) ~= 0; error('Each level must have same number of subjects!'); end;

% load all time-frequency data
tfdat = cell(1,length(groups.id));
for i=1:length(groups.id)
    file     = fullfile(groups.paths{i},groups.files{i});
    tfdat{i} = load(file);
end

% make an array to hold all of the time-frequency tests
tfsize  = size(tfdat{1}.tf.tpower);
dataarr = zeros(length(groups.id),tfsize(1),tfsize(2));

% extract the data to be tested
for i=1:length(groups.id)
    tmp         = getfield(tfdat{i}.tf,fname);
    size_tmp    = size(tmp);
    if size_tmp(1) ~= tfsize(1) || size_tmp(2) ~= tfsize(2)
        error('%s time-frequency sizes do not match first subject!',...
            char(groups.files{i}));
    else
        dataarr(i,:,:) = tmp;
    end
end

%make some empty structures for stats
Fvals = rmfield(tfdat{1}.tf,{'mplf' 'tpower' 'epower' 'ipower' ...
    'ntpower' 'nepower' 'nipower'});
clear tfdat;
Fvals.data=zeros(tfsize(1),tfsize(2));
Fvals.type='F-statistics';
pvals=Fvals;
pvals.type='p-values';

% make some empty structures for means
means = [];
for i=1:ngroups
    means.data(i)      = Fvals;
    means.data(i).type = ['Mean Group ' num2str(i)];
end

%compute stats
for i=1:tfsize(1)
    for j=1:tfsize(2)
        data = dataarr(:,i,j);
        data = reshape(data,[],ngroups);
        if sphericity
            [p F model]     = oneway_rm_anova(data,tails,'GG');
        else
            [p F model]     = oneway_rm_anova(data,tails);
        end
        Fvals.data(i,j) = F;
        pvals.data(i,j) = p;
    end
end

% save results