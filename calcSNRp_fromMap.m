function [SNRp, Pds, Pdn, peakVal, peakFreqIdx, peakCodeIdx] = calcSNRp_fromMap(resultMap)
% resultMap : [numFreqBins x numCodePhases]
%
% Output:
%   SNRp        : detection SNR in dB
%   Pds         : signal power
%   Pdn         : noise power
%   peakVal     : global maximum value
%   peakFreqIdx : Doppler-bin index of peak
%   peakCodeIdx : code-phase index of peak

    % 1) 전체 맵에서 가장 큰 피크 찾기
    [peakPerFreq, codeIdxPerFreq] = max(resultMap, [], 2);
    [peakVal, peakFreqIdx] = max(peakPerFreq);
    peakCodeIdx = codeIdxPerFreq(peakFreqIdx);

   % peak row 추출
    oneRow = resultMap(peakFreqIdx, :);
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