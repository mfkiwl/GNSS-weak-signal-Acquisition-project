function [bestMap, oddAccumMap, evenAccumMap, blockMaps, frqBins] = Differential_coherent(signalIn, PRN, settings)

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

    oddMetric  = abs(oddAccumMap);
    evenMetric = abs(evenAccumMap);

    oddPeak  = max(oddMetric(:));
    evenPeak = max(evenMetric(:));

    if oddPeak >= evenPeak
        bestMap = oddMetric;
    else
        bestMap = evenMetric;
    end
end