function [corrMapComplex, frqBins] = CoherentIntegrationN(signalBlock, PRN, settings, cohTimeMs)

    samplesPerCode = round(settings.samplingFreq / ...
        (settings.codeFreqBasis / settings.codeLength));

    neededSamples = cohTimeMs * samplesPerCode;

    signalBlock = signalBlock(:).';

    if length(signalBlock) < neededSamples
        error('signalBlock is shorter than required coherent integration length.');
    end

    signalBlock = signalBlock(1:neededSamples);

    corrMapComplex = [];
    frqBins = [];

    for msIdx = 1:cohTimeMs
        startIdx = (msIdx-1)*samplesPerCode + 1;
        endIdx   = msIdx*samplesPerCode;

        oneMsBlock = signalBlock(startIdx:endIdx);

        [corr1ms, frqBins] = CoherentIntegration(oneMsBlock, PRN, settings,1);

        if msIdx == 1
            corrMapComplex = corr1ms;
        else
            corrMapComplex = corrMapComplex + corr1ms;
        end
    end
end