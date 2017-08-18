function nirx_plot_gains(stats)
% function to plot gain info by distance for QC
% inputs:
%   stats = struct from nirx_chan_dist
%
    figure('color','w');
    b=bar(1:length(stats.mgain),stats.mgain,'b'); hold on; 
    h=errorbar(1:7,stats.mgain,stats.sdgains,'r'); 
    set(h,'linestyle','none');
    set(gca,'XtickLabel',stats.gainbins)
    xlabel('S-D Distances'); ylabel('Mean Gains +/- SD');
    l=line([0,8],[8,8],'linestyle','--');
end