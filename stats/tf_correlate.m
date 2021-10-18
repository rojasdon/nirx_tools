% script to create correlations between a vector regressor of interest and
% a series of saved time-frequency data

% assumes you have tf files saved and a text file of a regressor, 1 per
% time-frequency file, in alpha-numeric order
fname   = 'mplf'; % the name of the field in the tf structure you want to test

% get files for time frequency results and the regressor 
[list tfpath]       = uigetfile('*r40_tft.mat','MultiSelect','on',...
                        'Select time-freq files');
[varfile vpath]     = uigetfile('*.txt','MultiSelect','off',...
                        'Select file with regressor');
                    
% get regressor file data
reg = load(fullfile(vpath,varfile));

if length(list) ~= length(reg)
    error('Number of files must equal length of regressor variable!');
end

% load tf data
grp = cell(1,length(list));
for i=1:size(list,2)
    file    = fullfile(tfpath,char(list{i}));
    grp{i} =load(file);
end

%get some info from 1st file in group
tfsize  = size(grp{1}.tf.tpower);
arr     = zeros(length(list),tfsize(1),tfsize(2));

% extract the tf data to be tested
for i=1:length(list)
    tmp         = getfield(grp{i}.tf,fname);
    size_tmp    = size(tmp);
    if size_tmp(1) ~= tfsize(1) || size_tmp(2) ~= tfsize(2)
        error('%s time-frequency sizes do not match first subject!',...
            char(list{i}));
    else
        arr(i,:,:) = getfield(grp{i}.tf,fname);
    end
end

%make some empty structures
rvals = rmfield(grp{1}.tf,{'mplf' 'tpower' 'epower' 'ipower' ...
    'ntpower' 'nepower' 'nipower'});
clear grp;
rvals.data=zeros(tfsize(1),tfsize(2));
rvals.type='r-statistics';
pvals=rvals;
pvals.type='p-values';

%compute correlation
for i=1:tfsize(1)
    for j=1:tfsize(2)
        [r p]=corrcoef(arr(:,i,j),reg);
        rvals.data(i,j)=r(1,2);
        pvals.data(i,j)=p(2,1);
    end
end

% get corrected levels and masked r-values
ind             = find(rvals.mask);
p               = pvals.data(ind);
[pID,pN]        = FDR(p,.05);
rdat            = rvals.data;
nind            = find(rvals.mask < 1);
rdat(nind)      = NaN;
pvals.FDR       = pID;
rvals.masked    = rdat;
if isempty(pID); disp('No values survive FDR q < .05!'); end;
