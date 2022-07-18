% script to create t-test contrasts between two groups of time-frequency
% results. The t-test is conducted at every time-frequency bin.

fname = 'nepower'; % the name of the field in the tf structure you want to test
filter = 'l40';
type  = 1; % type of t-test  1-independent, equal, 2-independent, unequal, 3-dependent
tails = 1; % tails on t-test
bctype = 4; % type of baseline
savename = ['c_v_p_' filter '_' num2str(bctype) '_' fname];

% get file lists for group 1 and group 2
[list1 path1] = uigetfile(['*' filter '_tft.mat'],'MultiSelect','on','Select group 1');
[list2 path2] = uigetfile(['*' filter '_tft.mat'],'MultiSelect','on','Select group 2');

%list1 and 2 can be different lengths (i.e., group sizes)
grp1 = cell(1,length(list1));
grp2 = cell(1,length(list2));
for i=1:size(list1,2)
    file    = fullfile(path1,char(list1{i}));
    grp1{i} =load(file);
end

for i=1:size(list2,2)
    file    = fullfile(path2,char(list2{i}));
    grp2{i} = load(file);
end

%get some info from 1st file in group 1 - this sets what will be compared
tfsize  = size(grp1{1}.tf.tpower);
arr1    = zeros(length(list1),tfsize(1),tfsize(2));
arr2    = zeros(length(list2),tfsize(1),tfsize(2));

% extract the data to be tested
for i=1:length(list1)
    tmp         = getfield(grp1{i}.tf,fname);
    size_tmp    = size(tmp);
    if size_tmp(1) ~= tfsize(1) || size_tmp(2) ~= tfsize(2)
        error('%s time-frequency sizes do not match first subject!',...
            char(list1{i}));
    else
        arr1(i,:,:) = getfield(grp1{i}.tf,fname);
    end
end

for i=1:length(list2)
    tmp         = getfield(grp2{i}.tf,fname);
    size_tmp    = size(tmp);
    if size_tmp(1) ~= tfsize(1) || size_tmp(2) ~= tfsize(2)
        error('%s time-frequency sizes do not match first subject!',...
            char(list2{i}));
    else
        arr2(i,:,:) = getfield(grp2{i}.tf,fname);
    end
end

%make some empty structures
tvals = rmfield(grp1{1}.tf,{'mplf' 'tpower' 'epower' 'ipower' ...
    'ntpower' 'nepower' 'nipower'});
clear grp1 grp2;
tvals.data=zeros(tfsize(1),tfsize(2));
tvals.type='t-statistics';
pvals=tvals;
pvals.type='p-values';
mean1=tvals;
mean2=tvals;
mean1.type='Mean TFC';
mean2.type='Mean TFC';
mean1.condition='Group1Mean';
mean2.condition='Group2Mean';

%compute stats
for i=1:tfsize(1)
    for j=1:tfsize(2)
        [tval pval]=t_test(arr1(:,i,j),arr2(:,i,j),type,tails);
        avg1=mean(arr1(:,i,j));
        avg2=mean(arr2(:,i,j));
        mean1.data(i,j)=avg1;
        mean2.data(i,j)=avg2;
        tvals.data(i,j)=tval;
        pvals.data(i,j)=pval;
    end
end

% save results
save(savename);