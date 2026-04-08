% =========================================================
% Empirical PDF of PNR under H0 (noise only) and H1 (signal present)
% Threshold gamma is automatically chosen so that P_FA ~= 0.01
%
% Required inputs:
%   noisePNR   : vector of PNR values for noise-only trials
%   signalPNR  : vector of PNR values for signal-present trials
% =========================================================
% noisePNR=zeros(1000,1);
%signalPNR_PRN19 = zeros(1002,1);

% --------- basic check / reshape ---------
noisePNR  = noisePNR(:);
signalPNR_PRN19 = signalPNR_PRN19(:);

if isempty(noisePNR) || isempty(signalPNR_PRN19)
    error('noisePNR and signalPNR must not be empty.');
end

% --------- threshold selection from H0 ---------
% gamma = 99th percentile of noisePNR  -> target P_FA about 0.01
gamma = prctile(noisePNR, 99);

% empirical probabilities
Pfa = sum(noisePNR >= gamma) / length(noisePNR);
Pd  = sum(signalPNR_PRN19 >= gamma) / length(signalPNR_PRN19);

fprintf('Selected threshold gamma = %.4f\n', gamma);
fprintf('Empirical P_FA = %.4f\n', Pfa);
fprintf('Empirical P_D  = %.4f\n', Pd);

% --------- histogram-based empirical PDF ---------
allData = [noisePNR; signalPNR_PRN19];

% number of bins can be adjusted
numBins = 40;
edges = linspace(min(allData), max(allData), numBins + 1);

figure;
hold on;
grid on;
box on;

h0 = histogram(noisePNR, edges, ...
    'Normalization', 'pdf', ...
    'DisplayStyle', 'stairs', ...
    'LineWidth', 2);

h1 = histogram(signalPNR_PRN19, edges, ...
    'Normalization', 'pdf', ...
    'DisplayStyle', 'stairs', ...
    'LineWidth', 2);

xline(gamma, 'k--', 'LineWidth', 2, ...
    'Label', '\gamma', ...
    'LabelOrientation', 'horizontal', ...
    'LabelVerticalAlignment', 'middle');

xlabel('PNR');
ylabel('Probability Density');
title(sprintf('Empirical PDF of PNR (P_{FA}=%.4f, P_D=%.4f)', Pfa, Pd));
legend([h0, h1], {'H_0: noise only', 'H_1: signal present'}, ...
    'Location', 'best');

hold off;

% --------- optional: smoother PDF using kernel density ---------
[f0, x0] = ksdensity(noisePNR);
[f1, x1] = ksdensity(signalPNR_PRN19);

figure;
hold on;
grid on;
box on;

p0 = plot(x0, f0, 'LineWidth', 2);
p1 = plot(x1, f1, 'LineWidth', 2);

xline(gamma, 'k--', 'LineWidth', 2, ...
    'Label', '\gamma', ...
    'LabelOrientation', 'horizontal', ...
    'LabelVerticalAlignment', 'middle');

% shade false alarm region under H0
idx0 = x0 >= gamma;
a0 = area(x0(idx0), f0(idx0), ...
    'FaceAlpha', 0.25, ...
    'LineStyle', 'none');

% shade detection region under H1
idx1 = x1 >= gamma;
a1 = area(x1(idx1), f1(idx1), ...
    'FaceAlpha', 0.25, ...
    'LineStyle', 'none');

xlabel('PNR');
ylabel('Probability Density');
title(sprintf('Smoothed PDF of PNR (P_{FA}=%.4f, P_D=%.4f)', Pfa, Pd));
legend([p0, p1, a0, a1], ...
    {'H_0: noise only', 'H_1: signal present', ...
     'False alarm region', 'Detection region'}, ...
    'Location', 'best');

hold off;