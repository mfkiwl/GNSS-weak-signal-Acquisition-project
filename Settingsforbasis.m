function settings = Settingsforbasis()


%   // Processing settings ====================================================
%   // Number of milliseconds to be processed used 36000 + any transients (see
%   // below - in Nav parameters) to ensure nav subframes are provided
  settings.msToProcess        = 70000; %     70000;        %[ms]d

%   // Move the starting point of processing. Can be used to start the signal
%   // processing at any point in the data record (e.g. for long records). fseek
%   // function is used to move the file read point, therefore advance is byte
%   // based only. 
  settings.skipNumberOfBytes     = 10*16e6;


%   // Data type used to store one sample
%   //settings.dataType           = 'schar';
  settings.dataType           = 'int8';


%   // Intermediate, sampling and code frequencies
%   //settings.IF                 = -4.5000e6;      5[Hz]
  settings.IF                 =3.45e6;         %4.129e6;      5[Hz]
  settings.RF                 =1575.42e6; 
  settings.samplingFreq       = 13.728e6;  %27.456e6;       %16.3677e6;//12.8e6//1.875e6//16.3677e6; %[Hz]
  settings.codeFreqBasis      = 1.023e6;      %[Hz]

  % Define number of chips in a code period
  settings.codeLength         = 1023;

%   // Acquisition settings ===================================================
%   // Skips acquisition in the script postProcessing.sci if set to 1
  settings.skipAcquisition    = 0;
%   // List of satellites to look for. Some satellites can be excluded to speed
%   // up acquisition
  settings.acqSatelliteList   = 1:32;         %[PRN numbers]
  % Band around IF to search for satellite signal. Depends on max Doppler
  settings.acqSearchBand      = 20;           % 14[kHz]
  % Threshold for the signal presence decision rule
  settings.acqThreshold       = 3;
 % Coherent integration time during acquisition (for GPS it can be from 1to 10 ms for current acquisition implementation)
  settings.acqCohIntegration = 10;
  
  settings.samplesPerChip = settings.samplingFreq / settings.codeFreqBasis;
  % Constants ==============================================================

  settings.c                  = 299792458;    % The speed of light, [m/s]
  settings.startOffset        = 68.802;       %[ms] Initial sign. travel time

