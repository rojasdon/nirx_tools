function [pvals tvals] = tft_ttest(type,tails)

%
list1 = spm_get([1,100],'*.tfc','Select group 1 files');
list2 = spm_get([1,100],'*.tfc','Select group 2 files');

%list1 and 2 can be different lengths (i.e., group sizes)
for i=1:size(list1,1)
    grp1(i)=readBESAtfc(list1(i,:));
end

for i=1:size(list2,1)
    grp2(i)=readBESAtfc(list2(i,:));
end

%get array size from first file - this limits the values for comparison
sz=size(grp1(1).Data)
arr1=zeros(size(list1,1),sz(1),sz(2),sz(3));
arr2=zeros(size(list2,1),sz(1),sz(2),sz(3));

for i=1:size(list1,1)
    arr1(i,:,:,:)=grp1(i).Data;
end

for i=1:size(list2,1)
    arr2(i,:,:,:)=grp2(i).Data;
end

%make some empty structures
tvals=grp1(1);
tvals.Data=tvals.Data*0;
pvals=tvals;
tvals.ConditionName='t-statistics';
tvals.DataType='T-Statistic';
pvals.ConditionName='p-values';
pvals.DataType='p-values';
mean1=tvals;
mean2=tvals;
mean1.DataType='Mean TFC';
mean2.DataType='Mean TFC';
mean1.ConditionName='Group1Mean';
mean2.ConditionName='Group2Mean';

%compute stats
for i=1:sz(1)
    for j=1:sz(2)
        for k=1:sz(3)
            [tval pval]=t_test(arr1(:,i,j,k),arr2(:,i,j,k),type,tails);
            avg1=mean(arr1(:,i,j,k));
            avg2=mean(arr2(:,i,j,k));
            mean1.Data(i,j,k)=avg1;
            mean2.Data(i,j,k)=avg2;
            tvals.Data(i,j,k)=tval;
            pvals.Data(i,j,k)=pval;
        end
    end
end

%write tvals and pvals to separate files
besa_writetfc(tvals);
besa_writetfc(pvals);
besa_writetfc(mean1);
besa_writetfc(mean2);