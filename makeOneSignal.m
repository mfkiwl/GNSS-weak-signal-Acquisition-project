function finsig = makeOneSignal(settings, numMs)

    %% -------------------------------------------------
    % PRN 선택
    %% -------------------------------------------------

    % ===== 1 =====
    % prn = 14;
    % snrDb = -29;
    % codePhase = 159;
    % dopplerHz = 4337;

    % =====  2 ====
    % prn = 1;
    % snrDb = -36;
    % codePhase = 245;
    % dopplerHz = -1789;

    % % ===== 3 =====
    % prn = 26;
    % snrDb = -39;
    % codePhase = 1000;
    % dopplerHz = 3754;

    % =====  4 =====
    prn = 19;
    snrDb = -40;
    codePhase = 897;
    dopplerHz = -2543;

    %% -------------------------------------------------
    % 기본 파라미터
    %% -------------------------------------------------

    samplesPerCode = round(settings.samplingFreq / ...
        (settings.codeFreqBasis / settings.codeLength));

    N = numMs * samplesPerCode;
    t = (0:N-1) / settings.samplingFreq;

    %% -------------------------------------------------
    % C/A code 생성
    %% -------------------------------------------------

    caTable = makeCaTable(settings);
    code1ms = caTable(prn, :);

    % numMs 만큼 반복
    codeSeq = repmat(code1ms, 1, numMs);

    %% -------------------------------------------------
    % Code phase 적용 (chip → sample 변환)
    %% -------------------------------------------------

    samplesPerChip = settings.samplingFreq / settings.codeFreqBasis;
    sampleDelay = round(codePhase * samplesPerChip);

    codeShifted = circshift(codeSeq, [0 sampleDelay]);

    %% -------------------------------------------------
    % Carrier (IF + Doppler)
    %% -------------------------------------------------

    carrier = exp(-1j * 2 * pi * (settings.IF + dopplerHz) * t);

    %% -------------------------------------------------
    % Clean signal 생성
    %% -------------------------------------------------

    cleanSig = codeShifted .* carrier;

    %% -------------------------------------------------
    % Power 정규화
    %% -------------------------------------------------

    cleanSig = cleanSig / sqrt(mean(abs(cleanSig).^2));

    %% -------------------------------------------------
    % SNR scaling
    %% -------------------------------------------------

    targetLinear = 10^(snrDb / 10);
    sig = sqrt(targetLinear) * cleanSig;

    %% -------------------------------------------------
    % Noise
    %% -------------------------------------------------
    
    noise = (randn(1,N) + 1j *randn(1,N) /sqrt(2));
    finsig = sig +noise;
    
    signalpower = mean(abs(sig).^2);
    noisepower = mean(abs(noise).^2);
    fprintf('signal power = %.6f\n', signalpower);
    fprintf('noise power = %.6f\n', noisepower);
    fprintf('actual SNR= %.3f\n', 10*log10(signalpower/noisepower));
end