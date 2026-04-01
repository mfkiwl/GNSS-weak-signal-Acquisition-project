function [bestMap, oddAccumMap, evenAccumMap, blockMaps, frqBins] = Differential_coherent(signalIn, PRN, settings)
% Differential-coherent accumulation using 10 ms coherent blocks
%
% INPUT
%   signalIn   : input signal vector
%   PRN        : PRN number
%   settings   : receiver settings struct
%
% OUTPUT
%   bestMap      : selected magnitude map
%   oddAccumMap  : accumulated odd differential map (complex)
%   evenAccumMap : accumulated even differential map (complex)
%   blockMaps    : cell array of coherent maps
%   frqBins      : Doppler bin vector

    cohTimeMs = 10;
    numBlocks = 20;

    samplesPerCode = round(settings.samplingFreq / ...
        (settings.codeFreqBasis / settings.codeLength));

    samplesPerBlock = cohTimeMs * samplesPerCode;

    neededSamples = numBlocks * samplesPerBlock;
    if length(signalIn) < neededSamples
        error('Input signal is too short. Need at least %d samples.', neededSamples);
    end

    % size will be determined from first block
    blockMaps = cell(1, numBlocks);
    frqBins = [];

    oddAccumMap = [];
    evenAccumMap = [];

    for blk = 1:numBlocks
        startIdx = (blk-1)*samplesPerBlock + 1;
        endIdx   = blk*samplesPerBlock;

        signalBlock = signalIn(startIdx:endIdx);

        [corrMapComplex, frqBins] = CoherentIntegrationN(signalBlock, PRN, settings, cohTimeMs);
        blockMaps{blk} = corrMapComplex;

        if blk == 1
            [nRow, nCol] = size(corrMapComplex);
            oddAccumMap  = zeros(nRow, nCol);
            evenAccumMap = zeros(nRow, nCol);
        end

        if blk >= 3
            blockMul = corrMapComplex .* conj(blockMaps{blk-2});

            if mod(blk, 2) == 1
                oddAccumMap = oddAccumMap + blockMul;
            else
                evenAccumMap = evenAccumMap + blockMul;
            end
        end
    end

    oddMetric  = abs(oddAccumMap).^2;
    evenMetric = abs(evenAccumMap).^2;

    oddPeak  = max(oddMetric(:));
    evenPeak = max(evenMetric(:));

    if oddPeak >= evenPeak
        bestMap = oddMetric;
    else
        bestMap = evenMetric;
    end
end