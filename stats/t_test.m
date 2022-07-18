function [tval pval] = t_test(arr1, arr2, type, tails)
%PURPOSE:   to calculate the t test and p value associated with it between
%           two arrays of numbers, assuming equal variance, from the
%           formula: t=(mean1 - mean2)/pooled var or unequal
%           variance, from the formula: t=(mean1 - mean2)/sqrt(var1+var2),
%           or finally, the paired t-test,
%           t=(mean1-mean2)/(var1+var2-2*covariance(arr1,arr2)/n)
%INPUTS:    arr1 = Arrays of numbers to compare
%           arr2 = same as arr1
%           type = type of ttest 1 and 2 are independent 
%                  ttests, 1 with pooled variance and 2 with 
%                  separate variance. 3=paired ttest.  
%           tails = 1 or 2 tailed test
%OUTPUT:    tval = t statistic (default)
%           pval = probability associated with tval
%USAGE:     (1) [t p]=t_test(X,Y,1,2) will output a t stat and p
%           value for the test between arrays X and Y, equal 
%           variance assumed and 2-tails
%           (2) [t p]=t_test(X,Y,3,2) will output a paired t stat and
%           two-tailed p value for the test between arrays X and Y (see note 2)                
%NOTE:      (1) adapted from Numerical Recipe ttest, tutest and tptest to
%           mimic the behavior of the t-test functions in MS
%           Excel.
%           (2) if a paired t-test is requested, arr1 and arr2 must
%           be of equal size.
%AUTHOR:    Don Rojas, Ph.D., U. of Colorado Health Sciences Center
%HISTORY:   02/06/2007  v1: First working version of program

%do some basic calculations on inputs
n1=length(arr1);
ave1=mean(arr1);
var1=std(arr1)^2;
n2=length(arr2);
ave2=mean(arr2);
var2=std(arr2)^2;
%calculate t statistic 1=equal var;2=unequal var;3=paired
if type == 1
    df=n1+n2-2;
    pvar=((n1-1)*var1+(n2-1)*var2)/df;
    tval=(ave1-ave2)/sqrt(pvar*((1.0/n1)+(1.0/n2)));
elseif type == 2
    df=((var1/n1)+(var2/n2))^2/((var1/n1)^2/((n1-1))+((var2/n2)^2/(n2-1)));
    svar=sqrt((var1/n1)+(var2/n2));
    tval=(ave1-ave2)/svar;
else
    if n1 ~= n2
        error('Error: Paired tests must have equal sized input arrays!');
    else
        cv = 0.0; % cv is variance term for pooled variance
        for i = 1:n1
            cv = cv + (arr1(i)-ave1)*(arr2(i)-ave2);
        end
        df = n1-1;
        cv=cv/df;
        sd=sqrt((var1+var2-(2.0*cv))/n1);
        tval=(ave1-ave2)/sd;
    end
end
%calculate probability value using incomplete beta function
pval=betainc(df/(df+(tval^2)),0.5*df,0.5);
if tails == 2
    pval = pval;
else
    pval = pval/2;
end