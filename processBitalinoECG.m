% Processes Bitalino ECG data
%
%  inputs: 
%     bitalino (structure)
%         .channelDesc (1D cell array of strings that describe data type, per below)
%           'ACC'  - accelerometer 
%           'EDA'  - electrodermal activity 
%           'ECG'  - electrocardiogram (Must be one of the channelDesc elements)
%           'RESP' - respiration
%           'BUZZ' - buzzer on or off (binary)
%           'LED'  - LED on or off (binary)
%         .data - 2D array; each column has data for one channel
%         .hpCutoff - defines cutoff in Hz for high pass filter
%         .plotPanTompkins - plot output of R-wave detector if == 1
%         .qrsAmpFilt - output of R wave detector, peak amplitude
%         .qrsIndexFilt - output of R wave detector, index of peak
%         .beatTimes - times of R wave peak (in seconds since rec start)
%         .ints - interval length (in seconds)
%
%   outputs:
%     bitalino (structure)
%         .ecgScaled - 1D column of ECG scaled to milliVolts
%         .samplingRate - integer value (Hz), from Bitalino txt file header
%         .xData - 1D array of timepoints for data in seconds
       
function [bitalino] = processBitalinoECG(bitalino)

%% determine which column of bitalino.data has ecg data
ecgCol = [];
for j = 1:length(bitalino.channelDesc)
    if strfind(lower(char(bitalino.channelDesc{j})),'ecg')
        ecgCol = j;
        break
    end
end

% Throw error if did not find ecg channel descriptor
if isempty(ecgCol)
   error('Did not find channel descriptor for ECG. Please check channel IDs and descriptors')  
end

%% scale time to seconds and ECG to mV
bitalino.samplingRate = bitalino.header.samplingRate; % sampleRate defined in openSignals (best to use 1000 Hz)
bitalino.xData = [1:size(bitalino.data,1)]'./bitalino.samplingRate; % for plots in seconds, define xData 
[bitalino.ecgScaled, doFlipECG] = ...
    convertBit2mV_bitalino_ECG(bitalino.data(:,ecgCol)); % scale ECG data to mV; determine if flip necessary for positive R wave

%% ensure R-wave is positive-going
% multiply scaled ECG by -1 if necessary to make R-wave positive-going
if doFlipECG
    bitalino.ecgScaled = -bitalino.ecgScaled;
end

%% high pass filter to remove movement, breathing artifacts
Wn = [bitalino.hpCutoff/(bitalino.samplingRate/2)]; % define cutoff for high pass 
[b,a]  = butter(3,Wn,'high'); % define Butterworth filter
bitalino.ecgFilt = filtfilt(b,a,bitalino.ecgScaled); % apply filter

%% Run Pan-Tompkins algorithm to find R-wave peaks
[bitalino.qrsAmpFilt,bitalino.qrsIndexFilt,delay_filt] = ...
    pan_tompkin(bitalino.ecgFilt,bitalino.samplingRate,bitalino.plotPanTompkins);

%% derive R wave peak (heart beat) times and infer RR intervals
bitalino.beatTimes = bitalino.xData(bitalino.qrsIndexFilt); % in seconds
bitalino.ints = diff(bitalino.beatTimes); % in seconds