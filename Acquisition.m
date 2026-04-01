function acqResults = Acquisition(longSignal, settings)
% acquisition_L1
% GPS L1 C/A acquisition using FFT-based correlation
%
% Inputs:
%   longSignal : received complex signal vector
%   settings   : receiver settings structure
%
% Outputs:
%   acqResults.carrFreq   : detected carrier frequencies for PRNs 1:32
%   acqResults.codePhase  : detected code phases for PRNs 1:32
%   acqResults.peakMetric : peak metric for PRNs 1:32
N
    %% Basic parameters
    samplesPerCode = round(settings.samplingFreq / ...
        (settings.codeFreqBasis / settings.codeLength));

    % Ensure row vector
    longSignal = longSignal(:).';

    % Need enough data
    requiredLen = 2 * settings.acqCohIntegration * samplesPerCode;
    if length(longSignal) < requiredLen
        error('Input signal is too short. Need at least %d samples.', requiredLen);
    end


    %% Time axis
    ts = 1 / settings.samplingFreq;
    phasePoints = (0 : (settings.acqCohIntegration * samplesPerCode - 1)) * 2 * pi * ts;

    %% Doppler search bins
    % Step = 1000 / (2*coherentIntegration) Hz
    numberOfFrqBins = round(settings.acqSearchBand * 2 * settings.acqCohIntegration) + 1;

    %% Generate sampled local C/A codes
    caCodesTable = makeCaTable(settings);
    caCodesTable1 = caCodesTable;

    % Extend code for coherent integration length
    for i = 1 : settings.acqCohIntegration - 1
        caCodesTable = [caCodesTable caCodesTable1]; %#ok<AGROW>
    end

    %% Initialize output
    acqResults.carrFreq   = zeros(1, 32);
    acqResults.codePhase  = zeros(1, 32);
    acqResults.peakMetric = zeros(1, 32);

    disp('(');

    %% Search all requested PRNs
    for PRN = settings.acqSatelliteList
         
        cohMatrix_fc0 = CoherentIntegration(longSignal, settings, PRN, settings.IF);
        
        cohMatrix_fc1 = CoherentIntegration(longSignal, settings, PRN, settings.IF +500);
    end
end