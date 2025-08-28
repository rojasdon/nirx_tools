% Purpose: to convert NIRx fNIRS data to .SNIRF format
% Author: Don Rojas
% Inputs:   hdr, from nirx_read_hdr.m
%           data, from nirx_read_wl.m
%           outfile, string name of output file
% Optional Input in Key/Val pairs:
%           1.'probe', probe structure containing
%               .source2d
%               .source3d
%               .detector2d
%               .detector3d
%           2. 'stimdur', [1 x nConditions] vector containing duration of stimuli/conditions
%               in experiment
%           
% NOTE: at present, both Homer3 and Brain AnalyzIR can read output from
%       this function. But some changes were made for Homer3 that seem out of
%       spec with official format. Example: source positions should be nSource x
%       3, but to make it work for Homer3, this is written as 3 x nSource.
%       AnalyzIR doesn't seem to care.
% Info: https://github.com/fNIRS/snirf/blob/v1.1/snirf_specification.md
% Todo: see comments in line, but also write helper for h5create/h5write
%       pairs to reduce complexity

function nirx_to_snirf(hdr,data,outfile,varargin)
    % parse input and set default options
    isProbe = false;
    isStimDur = false;
    if nargin < 3
        error('Must supply at least 3 arguments to function!');
    else
        if ~isempty(varargin)
            optargin = size(varargin,2);
            if (mod(optargin,2) ~= 0)
                error('Optional arguments must come in option/value pairs');
            else
                for option=1:2:optargin
                    switch lower(varargin{option})
                        case 'probe'
                            probeStruct = varargin{option+1};
                            isProbe = true;
                        case 'stimdur'
                            stimdur = varargin{option+1};
                            isStimDur = true;
                        otherwise
                            error('Invalid option!');
                    end
                end
            end
        end
    end

    % path info
    [path_to_file, filename, fileext] = fileparts(outfile);
    if strcmpi(fileext,'snirf')
        outfile = [outfile '.snirf'];
    end
    if isempty(path_to_file)
        outfile = fullfile(pwd,[filename fileext]);
    end

    % version
    h5create(outfile,'/formatVersion',1, 'Datatype', 'string');
    h5write(outfile,'/formatVersion',"1.1");

    % check outfile
    if isfile(outfile)
        delete(outfile); % hdfcreate/write won't update file
    end

    % see if there is probeinfo in optional input
    if isProbe
        % determine type of info supplied
        if isfield(probeStruct,'probes')
            probetype = 'nirx';
            probe.source3d = probeStruct.probes.coords_s3 * 1e1; % cm to mm
            probe.detector3d = probeStruct.probes.coords_d3 * 1e1;
            probe.source2d = probeStruct.probes.coords_s2 * 1e1;
            probe.detector2d = probeStruct.probes.coords_d2 * 1e1;
        elseif isfield(probeStruct,'pos3d')
            probetype = 'custom'; % might be from nirx_read_optpos.m
            s_idx = find(labels.contains('S'));
            d_idx = find(labels.contains('D'));
            probe.source3d = probeStruct.pos3d(s_idx,:); % already in mm
            probe.detector3d = probeStruct.pos3d(d_idx,:);
            probe.source2d = probeStruct.pos2d(s_idx,:);
            probe.detector2d = probeStruct.pos2d(d_idx,:);
        end
    end
    
    % write stim field, if any - determine if stim info in hdr: todo,
    % optional pass of stim info from .evt file
    if isfield(hdr,'events')
        codes = double(unique([hdr.events.code]));
        nevents = length(codes);
        if isStimDur
            if length(stimdur) ~= length(codes)
                error('Error: stimulus durations must be same as conditions in number!');
            end
        else
            stimdur = 1; % default duration in s, can change later in whatever processing software used
        end
        for c = 1:nevents
            c_ind = find([hdr.events.code] == codes(c));
            starttimes = [hdr.events(c_ind).time];
            durations = double(repmat(stimdur(c),1,length(starttimes)));
            values = double([hdr.events(c_ind).code]);
            stimdata{c} = [starttimes' durations' values'];
        end
        for c = 1:nevents
            stimPath = sprintf('/nirs/stim%d', c);
            h5create(outfile, [stimPath '/name'], length(string(codes(c))), 'Datatype', 'string');
            h5write(outfile, [stimPath '/name'], string(codes(c)));
            h5create(outfile, [stimPath '/data'], size(stimdata{c}), 'Datatype', 'double');
            h5write(outfile, [stimPath '/data'], stimdata{c});
        end
    end

    % write probe
    nSrc = hdr.sources;
    nDet = hdr.detectors;
    probeField = '/nirs/probe';
    h5create(outfile, [probeField '/wavelengths'], length(hdr.wl), 'Datatype', 'double');
    h5write(outfile, [probeField '/wavelengths'], hdr.wl);
    h5create(outfile, [probeField '/sourcePos2D'], [2 nSrc], 'Datatype', 'double'); % should be [nSrc 2] according to format spec, but homer won't read it
    h5write(outfile, [probeField '/sourcePos2D'], probe.source2d');
    h5create(outfile, [probeField '/sourcePos3D'], [3 nSrc], 'Datatype', 'double');
    h5write(outfile, [probeField '/sourcePos3D'], probe.source3d');
    h5create(outfile, [probeField '/detectorPos2D'], [2 nDet], 'Datatype', 'double');
    h5write(outfile, [probeField '/detectorPos2D'], probe.detector2d');
    h5create(outfile, [probeField '/detectorPos3D'], [3 nDet], 'Datatype', 'double');
    h5write(outfile, [probeField '/detectorPos3D'], probe.detector3d');

    % snirf needs 2d data, not 3d, so order wl1 then wl2
    if ndims(data) > 2
        data = [squeeze(data(1,:,:)) squeeze(data(2,:,:))];
        data = data'; % delete if this not causing Homer3 prob
    end

    % create an hdf5 file at specified location and write data
    fprintf("Writing data to %s\n",outfile);
    npoints = size(data,2); % change to data,1 if this not causing Homer3 prob
    time = (0:npoints-1)'/hdr.sr;
    h5create(outfile, '/nirs/data1/dataTimeSeries', size(data), 'Datatype', 'double');
    h5write(outfile, '/nirs/data1/dataTimeSeries', data);
    h5create(outfile, '/nirs/data1/time', size(time), 'Datatype', 'double');
    h5write(outfile, '/nirs/data1/time', time); % option 1 in format

    % Metadata, parsing header for date
    t = datetime("today"); % temporary, until hdr read of date is fixed
    t.Format = 'yyyy-dd-MM';
    
    metaFields = sprintf('/nirs/metaDataTags');
    h5create(outfile,[metaFields '/SubjectID'],1,'Datatype','string');
    h5write(outfile,[metaFields '/SubjectID'], "anonymous"); % change to input from function
    h5create(outfile,[metaFields '/MeasurementDate'],1,'Datatype','string');
    h5write(outfile,[metaFields '/MeasurementDate'], string(t));
    % Try format with milliseconds first
    try
        dt = datetime(hdr.time, 'InputFormat','HH:mm:ss.SSS',TimeZone = 'local');
    catch
        % Fallback: assume hh:mm AM/PM format
        dt = datetime(hdr.time, 'InputFormat','hh:mm a',TimeZone = 'local');
    end
    % Return time in hh:mm:ss.SSS z format
    timeStr = char(datetime(dt,'Format','HH:mm:ss.SSS z'));
    h5create(outfile,[metaFields '/MeasurementTime'],1,'Datatype','string');
    h5write(outfile,[metaFields '/MeasurementTime'], string(timeStr));
    h5create(outfile,[metaFields '/LengthUnit'],1,'Datatype','string');
    h5write(outfile,[metaFields '/LengthUnit'], "cm");
    h5create(outfile,[metaFields '/TimeUnit'],1,'Datatype','string');
    h5write(outfile,[metaFields '/TimeUnit'], "s");
    h5create(outfile,[metaFields '/FrequencyUnit'],1,'Datatype','string');
    h5write(outfile,[metaFields '/FrequencyUnit'], "Hz");

    % Channel information
    nWL  = numel(hdr.wl);
    nChan = hdr.nchan;
    % loop over wl and chan
    for wl = 1:nWL
        dt = 1;                % dataType, 1 = CW
        dt_idx = 1;            % dataTypeIndex (sequential data type block index)
        for chn = 1:nChan
            %fprintf("Writing channel info: WL:%d\tChn:%d\n",wl,chn);
            src_idx = hdr.SDpairs(chn,1);        % integer index of source for this channel
            det_idx = hdr.SDpairs(chn,2) ;       % detector index
            % Create group by writing a dummy attribute or using h5create on one field
            switch wl
                case 1
                    measPath = sprintf('/nirs/data1/measurementList%d', chn);
                case 2
                    measPath = sprintf('/nirs/data1/measurementList%d', hdr.nchan + chn);
            end
            h5create(outfile, [measPath '/sourceIndex'], 1, 'Datatype', 'int32'); % int32 or int16?
            h5write(outfile, [measPath '/sourceIndex'], int32(src_idx));
            h5create(outfile, [measPath '/detectorIndex'], 1, 'Datatype', 'int32');
            h5write(outfile, [measPath '/detectorIndex'], int32(det_idx));
            h5create(outfile, [measPath '/wavelengthIndex'], 1, 'Datatype', 'int32');
            h5write(outfile, [measPath '/wavelengthIndex'], int32(wl));
            h5create(outfile, [measPath '/dataType'], 1, 'Datatype', 'int32');
            h5write(outfile, [measPath '/dataType'], int32(dt));
            h5create(outfile, [measPath '/dataTypeIndex'], 1, 'Datatype', 'int32');
            h5write(outfile, [measPath '/dataTypeIndex'], int32(dt_idx));

            % detectorGain % could write these to measPath as well
        end
    end
    
end