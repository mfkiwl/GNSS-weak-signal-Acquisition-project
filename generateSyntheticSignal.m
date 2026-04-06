function longSignal = generateSyntheticSignal(settings)
% 4개의 weak GPS signal을 합성해서 하나의 수신신호 생성

    samplesPerCode = round(settings.samplingFreq / ...
        (settings.codeFreqBasis / settings.codeLength));

    numMs = 200;   % window length
    N = numMs * samplesPerCode;

    % 논문 표 조건
    sat(1).prn = 14;
    sat(1).snrDb = -29;
    sat(1).codePhase = 159;
    sat(1).dopplerHz = 4337;

    sat(2).prn = 1;
    sat(2).snrDb = -36;
    sat(2).codePhase = 245;
    sat(2).dopplerHz = -1789;

    sat(3).prn = 26;
    sat(3).snrDb = -39;
    sat(3).codePhase = 1000;
    sat(3).dopplerHz = 3754;

    sat(4).prn = 19;
    sat(4).snrDb = -40;
    sat(4).codePhase = 897;
    sat(4).dopplerHz = -2543;

    % 각 위성 신호 합산
    longSignal = zeros(1, N);

    for k = 1:length(sat)
        longSignal = longSignal + makeOneSignal(settings, sat(k), numMs);
    end

    % 공통 복소 AWGN 추가
    noise = (randn(1, N) + 1j * randn(1, N)) / sqrt(2);
    longSignal = longSignal + noise;
end