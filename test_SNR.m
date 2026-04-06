clear; clc; close all;

%% -------------------------------------------------
% Settings
%% -------------------------------------------------
settings = Settingsforbasis();

strongThreshold = 17.5;

%% -------------------------------------------------
% Load signal
%% -------------------------------------------------

numMs = 210;  %

%%load I/Q raw data
longSignal = loadsignalfile(settings);

%generate signal
% longSignal = makeOneSignal(settings, numMs);
longSignal = longSignal(:).';


%% -------------------------------------------------
% Basic parameters
%% -------------------------------------------------
samplesPerCode = round(settings.samplingFreq / ...
    (settings.codeFreqBasis / settings.codeLength));

samples1ms   = samplesPerCode; 
samples200ms = 200 * samplesPerCode;
samples10ms = 10* samplesPerCode;

if length(longSignal) < samples200ms
    error('Input signal is shorter than 200 ms.');
end
    
signal1ms   = longSignal(1:samples1ms);
signal200ms = longSignal(1:samples200ms);
signal10ms = longSignal(1: samples10ms);

%% -------------------------------------------------
% Run PRN test
%% -------------------------------------------------
fprintf('\n==================== test_SNR start ====================\n');
fprintf('Strong threshold = %.2f\n\n', strongThreshold);

%for PRN = settings.acqSatelliteList

    %% 1 ms coherent integration
PRN = 1;
[corrMapComplex, frqBins] = CoherentIntegration(signal1ms, PRN, settings, 1);
    
[peakPerFreq, codeIdxPerFreq] = max(corrMapComplex, [], 2); %row마다 최대값 구함, 결과 모두 21*1
[peakVal, peakFreqIdx] = max(peakPerFreq);
peakCodeIdx = codeIdxPerFreq(peakFreqIdx);
peakChipIdx = round(peakCodeIdx/(samplesPerCode/settings.codeLength));

figure;

Z= abs(corrMapComplex);
 surf(Z);
 shading interp;
 colormap jet;
 colorbar;

 xlabel('Code Phase(samples)');
 ylabel('Doppler Bin');
 zlabel('Correlation Value');

 title(['3D Acquisition Map(PRN', num2str(PRN),')']);
 view(45,60);

 %%-----------------------------------------
 % Stong/weak signal discrimination
 %%---------------------------------------

% peak row 추출
oneRow = Z(peakFreqIdx, :);
N = length(oneRow);

% peak 주변 9개 (±4)
signalIdx = (peakCodeIdx-4):(peakCodeIdx+4);
signalIdx = signalIdx(signalIdx >= 1 & signalIdx <= N);

% 나머지 = noise
noiseMask = true(1, N);
noiseMask(signalIdx) = false; %9개 sample 에 대해서는 0처리

signalVals = oneRow(signalIdx);
noiseVals  = oneRow(noiseMask);

% noise 평균 b
b = mean(noiseVals);

% referecne 식
Pds = mean((signalVals - b).^2);
Pdn = mean((noiseVals - b).^2);

% SNR
SNRp = 10*log10(Pds / Pdn);

%% 출력

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
        Differential_coherent(longSignal, PRN, settings);

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

    [peakPerFreqZ2, codeIdxPerFreqZ2] = max(Z2, [], 2); %row마다 최대값 구함, 결과 모두 21*1
    [peakValZ2, peakFreqIdxZ2] = max(peakPerFreqZ2);
    peakCodeIdxZ2 = codeIdxPerFreqZ2(peakFreqIdxZ2);
    peakChipIdxZ2 = round(peakCodeIdxZ2/(samplesPerCode/settings.codeLength));


    fprintf('\n---After block accumulation-----\n')
    fprintf('PRN = %d\n', PRN);
    fprintf('Peak Value = %.3f\n', peakValZ2);
    fprintf('Doppler = %.3f Hz\n', frqBins(peakFreqIdxZ2)-settings.IF);
    fprintf('Code Phase = %d\n', round(peakChipIdxZ2));


    [fineDoppler, fineCodePhase] = finesearch(longSignal, PRN, settings, ...
        frqBins(peakFreqIdxZ2), peakCodeIdxZ2);
    fineChip = round(fineCodePhase/(samplesPerCode/settings.codeLength));
end

fprintf('\n===================== Final value=====================\n');
fprintf('Final Doppler offset: %.3f Hz\n', fineDoppler - settings.IF);
fprintf('Final Code Phase %d\n',fineChip );

fprintf('\n===================== test_SNR end =====================\n');
