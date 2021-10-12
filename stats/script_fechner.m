% script to produce psychophysical output from 2AFC procedure. PSE and
% 25/75 thresholds are determined and a plot is made

% NOTE: requires stats toolbox and logistic.m function

% defaults
Np = .01; % steps for prettier figure output
start = 1;
stop = 7;
fname = 'logistic-result.mat';

% define column vectors for X and Y here...

% calculate the fit
[B,Dev,Stat] = glmfit(X,[Y ones(length(X),1)],'binomial','link','logit');
Z = B(1) + X * (B(2));
O = logistic(Z);

% finer res output
Xp=start:Np:stop;
Zp = B(1) + Xp * (B(2));
Op=logistic(Zp);

% PSE, JND
[~,ind]=min(abs(Op - .5));
PSE = Xp(ind);
[~,ind]=min(abs(Op - .25));
JND25 = Xp(ind);
[~,ind]=min(abs(Op - .75));
JND75 = Xp(ind);

% plot fit
figure('color','white');
plot(Xp,Op);
set(gca,'Fontsize',16);

% save result
save(fname,'Xp','Op','Stat','PSE','JND25','JND75');