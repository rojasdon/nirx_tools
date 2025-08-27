% Purpose: to convert NIRx fNIRS data to .SNIRF format
% Author: Don Rojas
% Inputs:   hdr, from nirx_read_hdr.m
%           data, from nirx_read_wl.m
%           outfile, string name of output file
% Optional Input: probe structure containing
%           .source2d
%           .source3d
%           .detector2d
%           .detector3d
% NOTE: at present, both Homer3 and Brain AnalyzIR can read output from
% this function. But some changes were made for Homer3 that seem out of
% spec with official format. Example: source positions should be nSource x
% 3, but to make it work for Homer3, this is written as 3 x nSource.
% AnalyzIR doesn't seem to care.
function nirx_to_snirf(hdr,data,outfile,varargin)

    % path info
    [path_to_file, filename, fileext] = fileparts(outfile);
    if strcmpi(fileext,'snirf')
        outfile = [outfile '.snirf'];
    end

    % version
    h5create(outfile,'/formatVersion',1, 'Datatype', 'string');
    h5write(outfile,'/formatVersion',"1.0");

    % check outfile
    if isfile(outfile)
        delete(outfile); % hdfcreate/write won't update file
    end

    % see if there is probeinfo in optional input
    if isfield(varargin{1},'probes')
        tmp = varargin{1}; %
        probetype = 'nirx';
        probe.source3d = tmp.probes.coords_s3 * 1e1; % cm to mm
        probe.detector3d = tmp.probes.coords_d3 * 1e1;
        probe.source2d = tmp.probes.coords_s2 * 1e1;
        probe.detector2d = tmp.probes.coords_d2 * 1e1;
    elseif isfield(varargin{1},'sourcePos')
        tmp = varargin{1};
        probetype = 'custom';
        s_idx = find(labels.contains('S'));
        d_idx = find(labels.contains('D'));
        probe.source3d = tmp.pos3d(s_idx,:); % already in mm
        probe.detector3d = tmp.pos3d(d_idx,:);
        probe.source2d = tmp.pos2d(s_idx,:);
        probe.detector2d = tmp.pos2d(d_idx,:);
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
    t = datetime(hdr.time,'InputFormat','HH:mm a');
    t.TimeZone ='America/Denver';
    t.Format = 'h:mm a z';
    h5create(outfile,[metaFields '/MeasurementTime'],1,'Datatype','string');
    h5write(outfile,[metaFields '/MeasurementTime'], string(t));
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
            h5create(outfile, [measPath '/sourceIndex'], 1, 'Datatype', 'int16'); % int32 or int16
            h5write(outfile, [measPath '/sourceIndex'], int16(src_idx));
            h5create(outfile, [measPath '/detectorIndex'], 1, 'Datatype', 'int16');
            h5write(outfile, [measPath '/detectorIndex'], int16(det_idx));
            h5create(outfile, [measPath '/wavelengthIndex'], 1, 'Datatype', 'int16');
            h5write(outfile, [measPath '/wavelengthIndex'], int16(wl));
            h5create(outfile, [measPath '/dataType'], 1, 'Datatype', 'int16');
            h5write(outfile, [measPath '/dataType'], int16(dt));
            h5create(outfile, [measPath '/dataTypeIndex'], 1, 'Datatype', 'int16');
            h5write(outfile, [measPath '/dataTypeIndex'], int16(dt_idx));

            % detectorGain % could write these to measPath as well
        
            % Optional: add a label
            % h5create(outFile, [ml_group '/dataTypeLabel'], 1, 'Datatype', 'string');
            % h5write(outFile, [ml_group '/dataTypeLabel'], "CW");
        end
    end
    
end