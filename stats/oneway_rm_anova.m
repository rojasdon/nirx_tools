function [p F model] = oneway_rm_anova(data,varargin)
%PURPOSE:   to calculate the F and p value within a one-way, within subjects
%           ANOVA model
%INPUTS:    data = nsubjects x nlevels column array, where each subject is a row
%                  columns 1...n are observations within level n for each subject
%           tails = 1 or 2 tailed test (2 = default)
%           corr  = correction to apply for sphericity violation (currently
%                   corr must = 'GG' for Greenhouse-Geisser;
%OUTPUT:    p = probability value associated with F
%           F = F statistic
%           model = SS/MS/F values for table
%USAGE:     (1) [p F model] = oneway_rm_anova(data,1) will compute a
%               one-tailed significance test on the F stat from data
%AUTHOR:    Don Rojas, Ph.D., U. of Colorado Denver
%NOTES:     1. Some terminology/formulation follows discussion on Table 16-2, Keppel
%              and Zedeck, Data Analysis for Research Designs (1989)
%TODO:      1. Add different correction options for sphericity
%           2. Report Mauchley's test for sphericity
%           3. Add contrast vector input
%HISTORY:   08/05/10 - first working version

% check inputs
if nargin > 1; tails = varargin{1}; else tails = 2; end;
GG  = 0;
if nargin == 3
    if ~strcmp(varargin{2},'GG')
        warning('Third argument should be a string with the value GG');
    else
        GG = 1;
    end
end
if nargin > 3; error('This function can only take 3 arguments!'); end;

% degrees of freedom
nlevels   = size(data,2);
nsubjects = size(data,1);
df_T      = nlevels*nsubjects-1;
df_A      = nlevels - 1;
df_S      = nsubjects - 1;
df_AxS    = df_A*df_S;

% find various basic SS ratios
T = sum(data(:))^2/(nlevels*nsubjects);
A = sum(sum(data,1).^2)/nsubjects;
S = sum(sum(data,2).^2)/nlevels;
Y = sum(data(:).^2);

% calculate sums of squares
SS_A        = A - T;
SS_S        = S - T;
SS_AxS      = Y - A - S + T;
SS_Total    = Y - T;

% Greenhouse-Geisser correction - note we do not test for sphericity in
% this function, but only supply the GG correction factors
if GG
    epsilon         = epsGG(data);
else
    epsilon     = 1; % assumed if no GG correction
end

% F statistic and model
effect_df           = df_A*epsilon;
error_df            = df_AxS*epsilon;
MS_A                = SS_A/effect_df;
MS_AxS              = SS_AxS/error_df;
F                   = MS_A/MS_AxS;
model.effect_SS     = SS_A;
model.error_SS      = SS_AxS;
model.total_SS      = SS_Total;
model.effect_df     = effect_df;
model.error_df      = error_df;
model.total_df  	= df_T;
model.epsilon       = epsilon;
model.F             = F;

%calculate probability value using incomplete beta function
p = betainc(error_df./(error_df + effect_df.*F),error_df/2,effect_df/2);
if tails == 1
    p = p/2;
end