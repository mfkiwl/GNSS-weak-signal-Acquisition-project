%% main_acq_only.m
% L1 acquisition only test script
% Purpose:
%   1) Load L1 settings
%   2) Read raw I/Q data from file
%   3) Run L1 acquisition only
%   4) Plot and display acquisition results

close all;
clear;
clc;

format long;

%% Optional: add paths if needed
% Uncomment and modify only if your functions are in subfolders
% addpath('include');
% addpath('geoFunctions');

disp('==============================');
disp('   L1 Acquisition Test   ');
disp('==============================');

%% 1) Load settings
%% for basic code
%settings = settingsL1();

%% values based on reference
settings = Settingsforbasis();


%% 2) Read signal from file
%

%%load I/Q raw data
%longSignal = loadsignalfile(settings);

%%use generate signal
longSignal = generateSyntheticSignal(settings);

disp(['Loaded signal length: ', num2str(length(longSignal)), ' samples']);

%% 3) Run acquisition
disp('Running L1 acquisition...');
acqResults = Acquisition(longSignal, settings);

%% 4) Plot results
disp('Plotting acquisition results...');
plotAcquisition(acqResults);

%% 5) Display summary
disp('Acquisition finished.');
disp('--- acqResults fields ---');
disp(acqResults);

%% 6) Show detected PRNs only
detectedPRN = find(acqResults.carrFreq ~= 0);

if isempty(detectedPRN)
    disp('No satellites detected.');
else
    disp('Detected satellites:');
    for k = 1:length(detectedPRN)
        prn = detectedPRN(k);
        codePhaseSample = acqResults.codePhase(prn);
        codePhaseChip = round(codePhaseSample/ settings.samplesPerChip);
        fprintf('PRN %2d | PeakMetric = %8.4f | CodePhase = %8d | CarrFreq = %12.3f Hz\n', ...
            prn, ...
            acqResults.peakMetric(prn), ...
            codePhaseChip, ...
            acqResults.carrFreq(prn));
    end
end