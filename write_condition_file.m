function write_condition_file(file,names,triggers,trigvals,onsetvec,durationvec)
% function to write mat file containing design inputs for spm_fnirs
% inputs:
%   1. file = output file name
%   2. names = condition names
%   3. triggers = trigger codes , see nirx_read_evt.m
%   4. onsetvec = onsets, see nirx_read_evt
%   5. duractionvec = durations of events after onsets, should be same
%      timescale and unit as onsetvec
%
    for ii = 1:length(names)
        tind = find(trigvals == triggers(ii));
        onsets{ii} = onsetvec(tind)';
        durations{ii} = repmat(durationvec(ii),1,length(onsets{ii}));
    end
    save(file,'names','onsets','durations');
end