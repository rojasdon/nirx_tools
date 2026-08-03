function nirx_probeInfo2posfile(probefile,outfile)

% load probeFile from nirx
load(probefile);

% extract position information
pos = [probeInfo.probes.coords_s3; probeInfo.probes.coords_d3]*10;

% labels
for c = 1:32
    slbl{c} = ['S' num2str(c)];
end
for c = 1:39
    dlbl{c} = ['D' num2str(c)];
end
lbl = [slbl dlbl];

% write output file
fp = fopen(outfile,"w");
fprintf(fp,'Optode,X,Y,Z\n');
for c = 1:length(lbl)
    fprintf(fp,'%s,%.2f,%.2f,%.2f\n', lbl{c}, pos(c,1),pos(c,2),pos(c,3));
end
