function [corrMapComplex, frqBins] = CoherentIntegration(signalBlock, PRN, settings, cohTimeMs)

    %--------------------------------------------------------------
    % Basic parameters
    %--------------------------------------------------------------
    samplesPerCode = round(settings.samplingFreq / ...
        (settings.codeFreqBasis / settings.codeLength));   % 1 ms samples

    blockSamples = cohTimeMs * samplesPerCode;

    % Force row vector
    signalBlock = signalBlock(:).';

    if length(signalBlock) < blockSamples
        error('signalBlock is shorter than required coherent integration length.');
    end

    % Use only required portion
    signalBlock = signalBlock(1:blockSamples);

    %--------------------------------------------------------------
    % Doppler bin settings
    %--------------------------------------------------------------
    binStep = 500 ;  % Hz
    numberOfFrqBins = round(settings.acqSearchBand * 1000 / binStep) + 1;

    frqBins = settings.IF ...
        - (settings.acqSearchBand/2) * 1000 ...
        + binStep * (0:numberOfFrqBins-1);

    %--------------------------------------------------------------
    % Local code generation for 1 ms
    %--------------------------------------------------------------
    if exist('generateCAcode', 'file')
        caCode = generateCAcode(PRN);
    elseif exist('cacode', 'file')
        caCode = cacode(PRN);
    else
        error('generateCAcode.m or cacode.m is required.');
    end

    caCode = caCode(:).';  % row vector, 1023 chips

    % Sampled 1 ms code
    codeValueIndex = ceil((1:samplesPerCode) * settings.codeFreqBasis / settings.samplingFreq);
    codeValueIndex(codeValueIndex < 1) = 1;
    codeValueIndex(codeValueIndex > settings.codeLength) = settings.codeLength;

    sampledCode1ms = caCode(codeValueIndex);

    % Repeat code for cohTimeMs ms
    localCode = repmat(sampledCode1ms, 1, cohTimeMs);

    % FFT of local code
    localCodeFreqDom = conj(fft(localCode));

    %--------------------------------------------------------------
    % Time axis for carrier generation
    %--------------------------------------------------------------
    phasePoints = (0:blockSamples-1) * 2 * pi / settings.samplingFreq;

    %--------------------------------------------------------------
    % Output allocation
    %--------------------------------------------------------------
    corrMapComplex = zeros(numberOfFrqBins, blockSamples);
    
    %--------------------------------------------------------------
    % Doppler bin loop
    %--------------------------------------------------------------
    for frqBinIndex = 1:numberOfFrqBins

        carrFreq = frqBins(frqBinIndex);

        % Local carrier
        sigCarr = exp(1j * carrFreq * phasePoints);

        % Carrier wipeoff
        wipedSignal = sigCarr .* signalBlock;

        % FFT of wiped signal
        signalFreqDom = fft(wipedSignal);

        % Frequency-domain correlation
        freqDomProduct = signalFreqDom .* localCodeFreqDom;

        % Back to time domain
        corrVec = ifft(freqDomProduct);

        % Store
        corrMapComplex(frqBinIndex, :) = corrVec;
    end
    corrMapComplex = abs(corrMapComplex);
end