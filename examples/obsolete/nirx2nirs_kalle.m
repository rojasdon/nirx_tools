function [t,d,SD,s,ml,aux] = nirx2nirs_Kalle(filename)

%filename = 'P:\nirs\Kalle\Matlab\NIRx_dataset\1616Motor-2014-09-25_001\1616Motor-2014-09-25_001';

[onsets, vals] = nirx_read_evt([filename '.evt']);
nirx = nirx_read_hdr([filename '.hdr']);
[nirx_raw,cols,S,D] = nirx_read_wl(filename,nirx);

SD.Lambda = nirx.wl';
SD.nSrcs  = nirx.sources;
SD.nDets  = nirx.detectors;

ml = [];
t  = [0:1/nirx.sr:(size(nirx_raw,2)-1)/nirx.sr]';
d  = [];
channelnumber = 0;
for i = 1:size(nirx_raw,3), %%% channels
    for j = 1:size(nirx_raw,1), %%% wl
        channelnumber = channelnumber + 1;
        tmp = nirx_raw(j,:,i);
        d(:,channelnumber) = tmp';
        ml(channelnumber,:) = [S(i) D(i) 1 j];
    end    
end
SD.MeasList = ml;

s  = [];
for i = min(vals):max(vals),
    tmp_s = zeros(size(t));
    tmp_onsets = onsets(vals==i);
    if tmp_onsets,
        tmp_s(tmp_onsets) = 1;
        s = [s tmp_s];
    end
end


SD.DetPos = [
-36.158     -9.9839     89.752
-28.6203	-80.5249	75.436
-60.1819	22.7162     55.544
-63.5562	-47.0088	65.624
-80.2801	-13.7597	29.16
-67.2723	-76.2907	28.382
-80.775     14.1203     -11.135
-84.8302	-46.0217	-7.056
37.672      -9.6241     88.412
31.9197     -80.4871	76.716
62.2931     23.7228     55.63
66.6118     -46.6372	65.58
83.4559     -12.7763	29.208
67.8877     -75.9043	28.091
81.8151     15.4167     -11.33
85.5488     -45.5453	-7.13
];

SD.SrcPos = [
-34.0619	26.0111     79.987
-35.5131	-47.2919	91.315
-65.3581	-11.6317	64.358
-53.0073	-78.7878	55.94
-77.2149	18.6433     24.46
-79.5922	-46.5507	30.949
-84.1611	-16.0187	-9.346
-72.4343	-73.4527	-2.487
34.7841     26.4379     78.808
38.3838     -47.0731	90.695
67.1179     -10.9003	63.58
55.6667     -78.5602	56.561
79.5341     19.9357     24.438
83.3218     -46.1013	31.206
85.0799     -15.0203	-9.49
73.0557     -73.0683	-2.54
];

SD.SpatialUnit = 'mm';

aux = zeros(size(t)); 
