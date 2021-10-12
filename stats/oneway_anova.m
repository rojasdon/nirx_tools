function [p F model] = oneway_anova(data,varargin)
%PURPOSE:   to calculate the F and p value within a one-way, between subjects
%           ANOVA model
%INPUTS:    data = nsubjects x 2 column array, where each subject is a row
%           column 1 is a group code 1...n, and column 2 is the observed
%           data associated with that subject
%           tails = 1 or 2 tailed test (2 = default)
%OUTPUT:    p = probability value associated with F
%           F = F statistic
%           model = SS/MS/F values for table
%USAGE:     (1) [p F model] = oneway_anova(data) will compute a two-tailed
%               significance test on the F stat from the input data.
%           (2) [p F model] = oneway_anova(data,1) will compute a
%               one-tailed significance test on the F stat from data. p and
%               F reflect the omnibus statistic.
%           (3) [p F model] = oneway_anova(data,2,[0 1 -1]) will compute a
%               two-tailed anova using the contrast vector [0 1 -1]. p and F
%               values will reflect the contrast, NOT the omnibus F or
%               group main effect.
%AUTHOR:    Don Rojas, Ph.D., U. of Colorado Denver
%NOTES:     1.  Each version is checked with SPSS default output for glm and
%               oneway procedures using data from Keppel and Zedeck (1989),
%               Table 10.1 - data = [1 53;1 49;1 47;1 42;1 51;1 34;1 44;1 48;1 35;1 18;1 32;1 27;
%               2 47;2 42;2 39;2 37;2 42;2 33;2 13;2 16;2 16;2 10;2 11;2
%               6; 3 45;3 41;3 38;3 36;3 35;3 33;3 46;3 40;3 29;3 21;3 30;3 20]; 
%               For checks of unbalancing, delete one row from one group
%TODO:      1.  Add contrast vector input
%HISTORY:   08/05/10 - first working version
%           08/06/10 - revised for better consistency with oneway_rm_anova.m and
%                      corrected unbalanced design issue
%           08/10/10 - added contrast vector optional input, changed the
%                      way SS effect was calculated to make more general
        
% check input
if nargin < 2
    tails = 2;
else
    tails = varargin{1};
end

if nargin > 2
    contrast = varargin{2};
    if length(contrast) ~= length(groups)
        error('Length of contrast vector not equal to length of groups!');
    end
end

% find group codes, means, n's and sums of squares
groups      = unique(data(:,1));
ind         = cell(size(groups));
group_sums  = zeros(1,length(ind));
group_means = group_sums;
group_SS    = group_sums;
group_n     = group_sums;
gmean       = mean(data(:,2));
for i=1:length(ind)
    ind{i}          = find(data(:,1) == groups(i));
    group_sums(i)   = sum(data(ind{i},2));
    group_means(i)  = mean(data(ind{i},2));
    group_n(i)      = length(ind{i});
    group_SS(i)     = sum((data(ind{i},2) - mean(data(ind{i},2))).^2);
    group_dv(i)     = group_n(i)*(group_means(i)-gmean).^2;
end

% degrees of freedom
N         = length(data); % overall N
nlevels   = length(ind);
df_A      = nlevels - 1;
df_SA     = sum(group_n - 1);
df_T      = df_A + df_SA;

% if design is unbalanced, do some calculations
if sum(group_n - mean(group_n))
    hmean = nlevels/sum(1./group_n); % harmonic mean
    % sums of squares for contrast, if requested
    if exist('contrast','var')
        isum = fliplr(contrast.*-1);
        %diff = sum(group_means.*contrast);
        %SS_c = (hmean*diff^2)/sum(contrast.^2);
        %SS_A = SS_c;
        %df_A = 1; % not flexible now
    end
end


% find some basic SS ratios
T = sum(data(:,2))^2/N; % sum, then square and divide by total N
Y = sum(data(:,2).^2);  % square, then sum

% calculate sums of squares
SS_SA       = sum(group_SS); % pooled within group sums of squares
SS_Total    = Y - T;
SS_A        = sum(group_dv); % should approx = SS_Total - SS_SA to 9/10 decimal places

% mean square and model
effect_df           = df_A;
error_df            = df_SA;
MS_A                = SS_A/effect_df;
MS_SA               = SS_SA/error_df;
F                   = MS_A/MS_SA;
model.effect_SS = SS_A;
model.error_SS  = SS_SA;
model.total_SS  = SS_Total;
model.effect_df = effect_df;
model.total_df  = df_T;
model.error_df  = error_df;
model.F         = F;

%calculate probability value using incomplete beta function
p = betainc(error_df./(error_df + effect_df.*F),error_df/2,effect_df/2);
if tails == 1
    p = p/2;
end