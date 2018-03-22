% script to plot visualize all possible channel distances given a set of
% coordinates for optodes. Useful for creating a ch_config.txt file for spm_fnirs

% must have optode_positions.csv file to work with
% file should have single header line: Ch, Source, Detector
% each line should have 3 csv values, e.g., "1,3,2" indicates channel 1 is
% source 3 and detector 2.

% Author: Don Rojas, Ph.D.

clear all;

% defaults
plotopt = 1; % set to zero to view raw distances for all channels
new_config = 1; % set to one to write a new ch_config.txt file based on your desired distances, set by thresh
thresh = [25 55];

% read file
posfile = 'optode_positions.csv';
[~,lbl,pos]=nirx_read_chpos(posfile);

% separate sources and detectors from labeling
sind = [];
dind = [];
for ii=1:length(lbl)
    if lbl{ii}{1}(1)=='S'
        sind = [sind ii];
    end
end
dind = setdiff(1:length(lbl),sind);
for ii=1:length(lbl)
    lbl(ii)=lbl{ii}; % to char for easier indexing
end

% sort the sources and detectors, if needed
Spos = pos(sind,:);
Dpos = pos(dind,:);
%Slbl = lbl(sind);
%[Slbl,Sorder] = sort(Slbl);
%Dlbl = lbl(dind);
%[Dlbl,Dorder] = sort(Dlbl);
%Spos = Spos(Sorder,:);
%Dpos = Dpos(Dorder,:);

% all possible channel distances
chdist = zeros(length(sind),length(dind));
for ii = 1:length(sind)
    for jj=1:length(dind)
        chdist(ii,jj) = sqrt(sum((Spos(ii,:) - Dpos(jj,:)).^2));
    end
end

% visualize
figure('color','w');
switch plotopt
    case 0
        imagesc(chdist);
    case 1
        ind = find(chdist >= thresh(1) & chdist <= thresh(2));
        dmat_thresh = zeros(size(chdist));
        dmat_thresh(ind) = chdist(ind);
        imagesc(dmat_thresh);
        caxis(thresh);
        fprintf('There are %d possible channels within your set distance criteria!\n',...
             length(ind));
        if new_config
            fprintf('Writing new configuration file based on acceptable distances.\n');
            ind = find(dmat_thresh);
            [Sfull,Dfull]=ind2sub(size(dmat_thresh),ind);
            chfile = 'ch_config_new.txt';
            fp = fopen(chfile,'w');
            fprintf(fp,'Ch, Source, Detector\n');
            fprintf('Ch, Source, Detector, Distance\n');
            for ii=1:length(ind)
                fprintf(fp,'%d, %d, %d\n', ii, Sfull(ii),...
                    Dfull(ii));
                fprintf('%d, %d, %d, %.2f\n', ii, Sfull(ii),...
                    Dfull(ii), chdist(ind(ii)));
            end
            fclose(fp);
        end
end
h=colorbar;
ylabel(h,'Distances');
xlabel('Detectors');
ylabel('Sources');