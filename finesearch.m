function [fineDoppler, fineCodePhase] = finesearch(longSignal, PRN, settings, coarseDoppler, coarseCodePhase)
% FINESEARCH  Fine frequency estimation
%
% 흐름:
%   1) coarseCodePhase 부터 1ms씩 200번 적분 → z[k] 200개
%   2) abs(z).^2 → 200개 실수 power 시계열
%   3) FFT → 잔여 도플러 Δf 탐색 (±250Hz, 5Hz 분해능)
%   4) fineDoppler = coarseDoppler + Δf
%
% 입력:
%   longSignal      - 210ms 이상 IF 샘플 벡터
%   PRN             - PRN 번호
%   settings        - Settings 구조체
%   coarseDoppler   - frqBins(peakFreqIdx) [Hz, IF 기준 절대값]
%   coarseCodePhase - peakCodeIdx [샘플]
%
% 출력:
%   fineDoppler     - 정밀 도플러 [Hz, IF 기준 절대값]
%   fineCodePhase   - 코드 위상 [샘플] (coarse 유지)

    %% ── 파라미터 ──────────────────────────────────────────────
    fs           = settings.samplingFreq;
    f_chip       = settings.codeFreqBasis;   % 1.023e6
    code_len     = settings.codeLength;      % 1023
    samplesPerMs = round(fs / (f_chip / code_len));

    N_epochs = 200;   % 200ms → 200 포인트 → 분해능 1000/200 = 5Hz
    N_fft    = 200;   % zero-padding 없음 → 딱 5Hz 격자

    %% ── 입력 길이 확인 ────────────────────────────────────────
    required = coarseCodePhase + N_epochs * samplesPerMs;
    if length(longSignal) < required
        error('[finesearch] longSignal 부족: 최소 %d 샘플 필요 (현재 %d)\nnumMs를 210 이상으로 늘려주세요.', ...
            required, length(longSignal));
    end

    %% ── C/A 코드 생성 (시프트 없이) ──────────────────────────
    ca_code = generateCAcode(PRN);   % 1×1023, {-1, +1}

    t_chip   = (0:samplesPerMs-1) / fs;
    chip_idx = mod(floor(t_chip * f_chip), code_len) + 1;
    ca_upsampled = ca_code(chip_idx);   % 1×samplesPerMs

    %% ── 200ms 적분 루프 ───────────────────────────────────────
    % coarseCodePhase부터 시작 → 코드 딜레이 자동으로 맞춰짐
    z = zeros(1, N_epochs);

    for k = 1:N_epochs
        i_start  = coarseCodePhase + (k-1) * samplesPerMs + 1;
        i_end    = i_start + samplesPerMs - 1;
        seg      = double(longSignal(i_start:i_end));

        % 1) 반송파 제거 (CoherentIntegration과 동일하게 +1j 부호)
        t_abs    = ((i_start-1):(i_end-1)) / fs;
        carrier  = exp(+1j * 2*pi * coarseDoppler * t_abs);
        baseband = seg .* carrier;

        % 2) 코드 제거
        baseband = baseband .* ca_upsampled;

        % 3) 1ms 적분 → 복소수 1포인트
        z(k) = sum(baseband);
    end

    %% ── Power 시계열 → FFT ───────────────────────────────────
    z_sq  = z .^ 2;           % 복소수 제곱 (비트 반전 제거, 주파수 2배됨)
    Z_fft = fft(z_sq, N_fft); % FFT

    % 주파수 축: 0~999Hz → 500Hz 초과는 음수로 변환
    freq_axis = (0:N_fft-1) / N_fft * 1000;
    freq_axis(freq_axis > 500) = freq_axis(freq_axis > 500) - 1000;
    % 결과: 0, 5, ..., 495, -500, -495, ..., -5 (5Hz 격자)

    %% ── ±500Hz 범위에서 2Δf 탐색 ────────────────────────────
    search_mask = (abs(freq_axis) > 10) & (abs(freq_axis) <= 500);
    Z_search    = abs(Z_fft) .* search_mask;

    [~, peak_idx] = max(Z_search);
    peak_freq     = freq_axis(peak_idx);   % 2Δf
    delta_f       = -peak_freq/2;         % Δf (÷2 보정)

    %% ── 최종 출력 ────────────────────────────────────────────
    fineDoppler   = coarseDoppler + delta_f;
    fineCodePhase = coarseCodePhase;

    %% ── 디버그 출력 ──────────────────────────────────────────
    fprintf('\n--- Fine Frequency Search Result ---\n');
    fprintf('Coarse Doppler : %+.1f Hz  (offset: %+.1f Hz)\n', ...
        coarseDoppler, coarseDoppler - settings.IF);
    fprintf('delta_f        : %+.3f Hz\n', delta_f);
    fprintf('Fine Doppler   : %+.1f Hz  (offset: %+.1f Hz)\n', ...
        fineDoppler, fineDoppler - settings.IF);
    fprintf('Code Phase     : %d samples\n', fineCodePhase);

    %% ── 플롯 ─────────────────────────────────────────────────
    % figure;
    % [freq_sorted, sort_idx] = sort(freq_axis);
    % plot(freq_sorted, abs(Z_fft(sort_idx)));
    % hold on;
    % xline(peak_freq, 'r--', sprintf('2\\Deltaf = %+.0f Hz', peak_freq));
    % xline( 500, 'k:'); xline(-500, 'k:', '\\pm500Hz');
    % xlabel('Frequency [Hz]  (2\Deltaf 스케일)');
    % ylabel('|FFT|');
    % title(sprintf('Fine Search PRN%d | coarse=%+.0fHz | \\Deltaf=%+.0fHz | fine=%+.0fHz', ...
    %     PRN, coarseDoppler - settings.IF, delta_f, fineDoppler - settings.IF));
    % xlim([-600 600]);
    % grid on;
end