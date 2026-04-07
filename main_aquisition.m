%% main_acq_only.m
% L1 acquisition only test script
%   1) Load L1 settings
%   2) Read raw I/Q data from file 
%   3) Run L1 acquisition only (1ms)
%      signal discrimination(strong/weak)
%      differnetly coherent integration(weak)
%      Fine search (2.5Hz)
%   7) Plot and display acquisition results

close all; clear; clc;

disp('==============================');
disp('      L1 Acquisition    ');
disp('==============================');

%% 1) settings/ Basic parameters
% for basic code
%settings = settingsL1();

% values based on reference
settings = Settingsforbasis();

samplesPerCode = round(settings.samplingFreq / ...
    (settings.codeFreqBasis / settings.codeLength));

samples1ms   = samplesPerCode; 
samples200ms = 200 * samplesPerCode;
samples10ms = 10* samplesPerCode;

strongThreshold = 17.5;%SNRp
threshold = 2.2;

%% 2) Read signal from file

numMs = 210;

%%load I/Q raw data
% longSignal = loadsignalfile(settings, numMs);

%%use generate signal
longSignal = makeOneSignal(settings, numMs);

longSignal = longSignal(:).';

if length(longSignal) < samples200ms
    error('Input signal is shorter than 200 ms.');
end
    
signal1ms   = longSignal(1:samples1ms);
signal200ms = longSignal(1:samples200ms);
signal10ms = longSignal(1: samples10ms);

%% 3) Run acquisition
disp('Running L1 acquisition...');
PRN =1;
% for PRN = settings.acqSatelliteList
    [corrMapComplex, frqBins] = CoherentIntegration(signal1ms, PRN, settings, 1);
    Z= abs(corrMapComplex);
    
    [SNRp, Pds, Pdn, peakVal, peakFreqIdx, peakCodeIdx] = calcSNRp_fromMap(Z);
    peakChipIdx = round(peakCodeIdx/(samplesPerCode/settings.codeLength));

    fprintf('\n---  1ms coherent integration ---\n');
    fprintf('PRN = %d\n', PRN);
    fprintf('Peak Value = %.3f\n', peakVal);
    fprintf('Doppler = %.3f Hz\n', frqBins(peakFreqIdx)-settings.IF);
    fprintf('Code Phase = %d\n', peakChipIdx);
    fprintf('SNRp = %.3f dB\n', SNRp);

    if SNRp >= strongThreshold
        fprintf('→ STRONG SIGNAL\n');
        [fineDoppler, fineCodePhase] = finesearch(longSignal, PRN, settings, ...
            frqBins(peakFreqIdx), peakCodeIdx);
        fineChip = round(fineCodePhase/(samplesPerCode/settings.codeLength));
    
    else
        fprintf('→ WEAK SIGNAL\n');
        [bestMap, oddMap, evenMap, blockMaps, frqBins] = ...
            Differential_coherent(signal200ms, PRN, settings);

        figure;
        Z2= bestMap;
        surf(Z2);
        shading interp;
        colormap jet;
        colorbar;
    
        xlabel('Code Phase(samples)');
        ylabel('Doppler Bin');
        zlabel('Correlation Value');
    
        title(['After differentially-coherent(PRN', num2str(PRN),')']);
        view(45,60);

        [SNRp2, Pds2, Pdn2, peakVal2, peakFreqIdx2, peakCodeIdx2] = calcSNRp_fromMap(Z2);
        peakChipIdx2 = round(peakCodeIdx2/(samplesPerCode/settings.codeLength));

        fprintf('\n---After block accumulation-----\n')
        fprintf('PRN = %d\n', PRN);
        fprintf('Peak Value = %.3f\n', peakVal2);
        fprintf('Doppler = %.3f Hz\n', frqBins(peakFreqIdx2)-settings.IF);
        fprintf('Code Phase = %d\n', round(peakChipIdx2));

         [fineDoppler, fineCodePhase] = finesearch(longSignal, PRN, settings, ...
            frqBins(peakFreqIdx2), peakCodeIdx2);
        fineChip = round(fineCodePhase/(samplesPerCode/settings.codeLength));

        fprintf('\n===================== Final value=====================\n');
        fprintf('PRN: ', PRN)
        fprintf('Final Doppler offset: %.3f Hz\n', fineDoppler - settings.IF);
        fprintf('Final Code Phase %d\n',fineChip );
    end
% end 