function longSignal = loadsignalfile(settings)
% loadSignalFromFile
% Reads raw GNSS data from file and returns complex signal vector
%
% Input:
%   settings : receiver settings structure
%
% Output:
%   longSignal : complex signal vector for acquisition

    %% Open file
    [fid, message] = fopen(settings.fileName, 'rb');

    if fid < 0
        error('Unable to read file %s: %s.', settings.fileName, message);
    end

    %% Decide adaptation coefficient based on file type
    % fileType = 1 : real samples
    % fileType = 2 : interleaved I/Q samples
    if settings.fileType == 1
        dataAdaptCoeff = 1;
    else
        dataAdaptCoeff = 2;
    end

    %% Move file pointer
    fseekStatus = fseek(fid, dataAdaptCoeff * settings.skipNumberOfBytes, 'bof');
    if fseekStatus ~= 0
        fclose(fid);
        error('fseek failed. Check skipNumberOfBytes and file size.');
    end

    %% Number of samples per one C/A code period (1 ms)
    samplesPerCode = round(settings.samplingFreq / ...
        (settings.codeFreqBasis / settings.codeLength));

    %% Read enough data for acquisition
    % acquisition_L1 uses:
    %   signal1 = first acqCohIntegration * samplesPerCode
    %   signal2 = next  acqCohIntegration * samplesPerCode
    % and later fine frequency search uses longer segment
    %
    % The original lab code used 21 * samplesPerCode
    numSamplesToRead = dataAdaptCoeff * 21 * samplesPerCode;

    rawData = fread(fid, numSamplesToRead, settings.dataType);

    fclose(fid);

    if isempty(rawData)
        error('No data was read from file. Check file path and settings.');
    end

    %% Convert to complex signal if I/Q interleaved
    if dataAdaptCoeff == 2
        % rawData = [I0 Q0 I1 Q1 I2 Q2 ...]
        dataI = rawData(1:2:end);
        dataQ = rawData(2:2:end);

        longSignal = dataI + 1i * dataQ;
    else
        % real-only data
        longSignal = rawData;
    end

    %% Force row vector if needed
    longSignal = longSignal(:).';
end