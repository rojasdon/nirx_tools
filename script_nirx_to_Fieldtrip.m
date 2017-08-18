% script to convert processed NIRx data to Fieldtrip format for use in various
% other programs

ft = [];
fs = nirsData.HbDataInfo.fs;
ft.trial{1} = nirsData.Hbdata';
ft.fsample  = fs;
ft.time{1} = 0:size(nirsData.Hbdata,1)-1;
ft.time{1} = ft.time{1}.*(1/fs);
