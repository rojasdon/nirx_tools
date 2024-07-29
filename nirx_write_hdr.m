function nirx_write_hdr(file,hdr)
% PURPOSE: function to write nirx format header file
% AUTHOR: D. Rojas
% INPUTS: 1. file = name of file to write
%         2. hdr = hdr structure, see nirx_read_hdr.m
% OUTPUTS: none on command line, hdr file on disk
% EXAMPLE:
%   nirx_write_hdr('filename.hdr',hdr);
% HISTORY:
%   07/28/2024 - Added short channel output, crosstalk and darknoise fields
%                if present

% some older headers do not have certain fields and are encased in isfield
% logic below
fp = fopen(file,'w');
fprintf(fp,'[GeneralInfo]\n');
fprintf(fp,['FileName="' hdr.file '"\n']);
[~,dow] = weekday(date,'short');
fprintf(fp,['Date="' dow ', ' datestr(date,'mmm dd, yyyy') '"\n']);
fprintf(fp,['Time="' strtrim(datestr(clock, 'HH:MM PM')) '"\n']);
fprintf(fp,['Device="' hdr.device '"\n']);
if isfield(hdr,'source'); fprintf(fp,['Source="' hdr.source '"\n']);end
if isfield(hdr,'mod');fprintf(fp,['Mod="' hdr.mod '"\n']);end
if isfield(hdr,'ver');fprintf(fp,['NIRStar="' num2str(hdr.ver) '"\n']);end
fprintf(fp,['Subject=' num2str(hdr.sub) '\n']);
fprintf(fp,'\n[ImagingParameters]\n');
fprintf(fp,['Sources=' num2str(hdr.sources) '\n']);
fprintf(fp,['Detectors=' num2str(hdr.detectors) '\n']);
fprintf(fp,['ShortBundles=' num2str(hdr.shortbundles) '\n']);
fprintf(fp,['ShortDetIndex="' num2str(hdr.shortdetindex) '"\n']);
if isfield(hdr,'ShortBundles'); fprintf(fp,['ShortBundles="' num2str(hdr.shortbundles) '"\n']); end
if isfield(hdr,'ShortDetIndex'); fprintf(fp,['ShortDetIndex="' num2str(nirx.shortdetindex) '"\n']); end
if isfield(hdr,'steps');fprintf(fp,['Steps=' num2str(hdr.steps) '\n']);end
fprintf(fp,['Wavelengths="' num2str(hdr.wl) '"\n']);
fprintf(fp,['TrigIns=' num2str(hdr.trigin) '\n']);
fprintf(fp,['TrigOuts=' num2str(hdr.trigout) '\n']);
fprintf(fp,['AnIns=' num2str(hdr.anins) '\n']);
fprintf(fp,['SamplingRate=' num2str(hdr.sr) '\n']);
if isfield(hdr,'mod');fprintf(fp,['ModAmp="' num2str(hdr.mod) '"\n']);end
fprintf(fp,['Threshold="' num2str(hdr.threshold) '"\n']);
fprintf(fp,'\n[Paradigm]\n');
fprintf(fp,['StimulusType="' hdr.stimtype '"\n']);
fprintf(fp,'\n[ExperimentNotes]\n');
fprintf(fp,['Notes="' hdr.notes '"\n']);
fprintf(fp,'\n[GainSettings]\nGains="#\n');
[nrows,ncols]= size(hdr.gains);
for ii=1:nrows
    for jj=1:ncols
        fprintf(fp,'%s\t',num2str(hdr.gains(ii,jj)));
    end
    fprintf(fp,'\n');
end
fprintf(fp,'#"\n');
fprintf(fp,'\n[Markers]\nEvents="#\n');
% events if present
if isfield(hdr,'events')
    if ~isempty(hdr.events)
        for ii=1:length(hdr.events)
            fprintf(fp,'%.2f\t%d\t%d\n',hdr.events(ii).time,hdr.events(ii).code,hdr.events(ii).samp);
        end
    else % create bogus event field for spm_fnirs_read_nirscout
        for ii=1:length(hdr.events)
            fprintf(fp,'%.2f\t%d\t%d\n',ii*2,99,round((ii*2)*hdr.sr));
        end
    end
    fprintf(fp,'#"\n');
end
fprintf(fp,'\n[DataStructure]\nS-D-Key="');
for ii=1:length(hdr.SDkey)
    fprintf(fp,'%s:%d,',hdr.SDkey{ii},ii);
end
fprintf(fp,'"\n');
fprintf(fp,'S-D-Mask="#\n');
for ii=1:nrows
    for jj=1:ncols
        fprintf(fp,'%s\t',num2str(hdr.SDmask(ii,jj)));
    end
    fprintf(fp,'\n');
end
fprintf(fp,'#"\n');
% Dark Noise, if present
if isfield(hdr,'DarkNoise')
    fprintf(fp,'\n[DarkNoise]\nWavelength1="#\n');
    for ii=1:length(hdr.DarkNoise)
        fprintf(fp,'%.3f\t',hdr.DarkNoise(1,ii));
    end
    fprintf(fp,'\n#"');
    fprintf(fp,'\nWavelength2="#\n');
    for ii=1:length(hdr.DarkNoise)
        fprintf(fp,'%.3f\t',hdr.DarkNoise(2,ii));
    end
    fprintf(fp,'\n#"\n');
end
% CrossTalk, if present (only if lights simultaneously illuminated)
if isfield(hdr,'CrossTalk')
    fprintf(fp,'\n[CrossTalk]\nWavelength1="#\n');
    for src=1:hdr.sources
        for det=1:hdr.detectors
            fprintf(fp,'%.2f\t',hdr.CrossTalk(1,src,det));
        end
        fprintf(fp,'\n');
    end
    fprintf(fp,'#"');
    fprintf(fp,'\nWavelength2="#\n');
    for src=1:hdr.sources
        for det=1:hdr.detectors
            fprintf(fp,'%.2f\t',hdr.CrossTalk(2,src,det));
        end
        fprintf(fp,'\n');
    end
    fprintf(fp,'#"\n');
end
fprintf(fp,'\n[ChannelsDistance]\nChanDis="');
for ii=1:length(hdr.dist)-1
    fprintf(fp,'%d\t',hdr.dist(ii));
end
fprintf(fp,'%d"',hdr.dist(end));
fclose(fp);