function model = mixed_anova(design,varargin)
% AUTHOR:   Don Rojas, Ph.D. University of Colorado Denver
% PURPOSE:  to calculate the F and p value within an m x n mixed model
%           ANOVA. Only 1 between subjects and 1 within subjects factor are
%           currently supported
% INPUTS:   design = nsubjects x nlevels + 1 column array, where each subject is a row
%           column 1 is a group or between subject's condition code 1...n, and column 2 ... n are the observed
%           data associated with that subject. There must be at least 3
%           columns in the data matrix, which would code 2 levels of one
%           repeated measure.
%           tails = 1 or 2 tailed test (2 = default)
% OUTPUTS:  model, contains F, MS, df and p information for between, within
%           and interaction term
% NOTES:    1) Refer to Kennedy and Bush(1985): An introduction to the design 
%              and analysis of experiments in behavioral research. 2nd ed. United Press.
%              for formulas guiding this function. 
%           2) Unbalanced designs accounted for by unweighted means
%              analysis (i.e., type III ss) - this is only true for
%              unbalancing resulting from unequal group sample sizes, not
%              from missing observations on the repeated measure (if the
%              latter is true, do not use this function).
%           3) Test data in K&B Table 9.5 come out exactly as in SPSS 19 using
%              GLM with repeated measure
% SEE ALSO: ONEWAY_ANOVA, ONEWAY_RM_ANOVA, T_TEST

% check input
if nargin < 2
    sourcetable = 0;
else
    sourcetable = varargin{1};
end
if size(design,2) < 3; error('There must be at least 3 columns in data matrix!'); end;

% check for nan - this might be due to a mistake or it might indicate an
% attempt to use an unbalanced repeated measure
if any(isnan(design(:)))
    error('NAN not accepted by this function!');
end

% find group codes and initialize variables
groups      = unique(design(:,1));
ngroups     = length(groups);
gind        = cell(size(groups));
group_n     = zeros(1,length(gind));
nlevels     = size(design,2) - 1;

% compute grand mean, cell means and marginal totals
data        = design(:,2:end);
for ii = 1:length(gind);
    gind{ii}                 = find(design(:,1) == groups(ii));
    group_data{ii}           = data(gind{ii},:);
    group_n(ii)              = length(find(design(:,1) == groups(ii)));
    cell_n(ii,:)             = repmat(group_n(ii),1,nlevels);
    cell_means(ii,1:nlevels) = mean(data(gind{ii},:));
    subj_subtotals(ii)       = sum(sum(data(gind{ii},:)));
    subj_ratios(ii)          = subj_subtotals(ii)^2/(nlevels*group_n(ii));
    group_subtot(ii,:)       = sum(group_data{ii});
    group_ratios(ii)         = sum(group_subtot(ii,:).^2)/group_n(ii);
end
level_totals = sum(cell_means,1);
group_totals = sum(cell_means,2);
subj_totals  = sum(data,2);
grand_total  = sum(cell_means(:));

% harmonic mean N per cell to account for unbalanced design
hmean = (ngroups*nlevels)/sum(1./cell_n(:));

% sums of squares
ncells   = numel(cell_means);
C        = grand_total^2/ncells;
SS_total = sum(cell_means(:).^2) - C;
SS_A     = (sum(group_totals.^2)/nlevels) - C;
SS_B     = (sum(level_totals.^2)/ngroups) - C;
SS_AB    = SS_total - SS_A - SS_B; % compute as residual SS
SS_SA    = (sum(subj_totals.^2)/nlevels) - sum(subj_ratios);
SS_SBA   = (sum(data(:).^2)) - (sum(subj_totals.^2)/nlevels) - sum(group_ratios) + sum(subj_ratios);

% adjusted sums of squares
SS_A     = hmean*SS_A;
SS_B     = hmean*SS_B;
SS_AB    = hmean*SS_AB;

% degrees of freedom
df_A      = ngroups - 1;
df_B      = nlevels - 1;
df_SA     = sum(group_n - 1);
df_AB     = df_A * df_B;
df_SBA    = df_B * df_SA;

% mean square and model
MS_A   = SS_A/df_A;
MS_B   = SS_B/df_B;
MS_SA  = SS_SA/df_SA;
MS_AB  = SS_AB/df_AB;
MS_SBA = SS_SBA/df_SBA;
model.between.MS            = MS_A;
model.between.MS_error      = MS_SA;
model.between.df            = df_A;
model.between.F             = MS_A/MS_SA;
model.within.MS             = MS_B;
model.within.MS_error       = MS_SBA;
model.within.df             = df_B;
model.within.F              = MS_B/MS_SBA;
model.interaction.MS        = MS_AB;
model.interaction.MS_error  = MS_SBA;
model.interaction.df        = df_SBA;
model.interaction.F         = MS_AB/MS_SBA;
model.total.SS              = SS_total;
model.total.df              = df_A+df_B+df_SA+df_AB+df_SBA;

% probability calculations
model.between.p         = betainc(df_SA./(df_SA + df_A*model.between.F),df_SA/2,df_A/2);
model.within.p          = betainc(df_SBA./(df_SBA + df_B*model.within.F),df_SBA/2,df_B/2);
model.interaction.p     = betainc(df_SBA./(df_SBA + df_AB*model.interaction.F),df_SBA/2,df_AB/2);

% print a source table, if requested
if sourcetable
    fprintf('%s\t%s\t%s\t%s\t%s\t%s\n','Source','SS','df','MS','F','p');
    fprintf('----------------------------------------------------\n');
    fprintf('%s\t%.2f\t%d\t%.2f\t%.2f\t%.4f\n','A',SS_A,df_A,MS_A,model.between.F,model.between.p);
    fprintf('%s\t%.2f\t%d\t%.2f\n','Error',SS_SA,df_SA,MS_SA);
    fprintf('----------------------------------------------------\n');
    fprintf('%s\t%.2f\t%d\t%.2f\t%.2f\t%.4f\n','B',SS_B,df_B,MS_B,model.within.F,model.within.p);
    fprintf('%s\t%.2f\t%d\t%.2f\n','Error',SS_SBA,df_SBA,MS_SBA);
    fprintf('----------------------------------------------------\n');
    fprintf('%s\t%.2f\t%d\t%.2f\t%.2f\t%.4f\n','AB',SS_AB,df_AB,MS_AB,model.interaction.F,model.interaction.p);
    fprintf('%s\t%.2f\t%d\t%.2f\n','Error',SS_SBA,df_SBA,MS_SBA);
end