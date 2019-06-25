% Converts  bitalino ECG data to milliVolts
% per Bitalino documentation
%
% Program will open a figure showing 15 seconds of ECG data
% Use mouse to click anywhere in plot near an R wave peak
% This is a simple way to ensure consistent orientation of signal
% even if electrodes are inadvertently swapped.
%
%  input: 
%     data - 1D vector of raw Bitalino ECG data
%
%   outputs:
%     bit2voltData - 1D vector of ECG data in mV
%     doFlipECG - if == 1, will later multiply by -1 so R-wave is positive-going

function [bit2voltData, doFlipECG] = convertBit2mV_bitalino_ECG(data)

%% First, determine if need to flip ECG signal so positive-going R-wave

% Plot 15 seconds of data 
figure
hold on;
plot(data(1:15000),'k-') % plot 15 seconds of data
plot([0,15000],ones(1,2).*(mean(data)),'r-') % plot mean ecg data value

% Title (instructions to user) and axis labels
title('Click approximate R-wave peak');
xlabel('Time');
ylabel('ecg voltage (a.u.)');
formataxes

% click once at approx R wave peak
% if click is above mean, ECG does not need to be flipped for R-wave to be
% positive-going; if click is below mean, ECG does need to be flipped
[junk,rPeakEst] = ginput(1); 

close % close fig

doFlipECG = 0;
if rPeakEst < mean(data) % if click < mean(ecg) multiply by -1 so R-wave is positive-going
    doFlipECG = 1;
end

%% Now convert to mV per data sheet from Bitalino

bit2voltData=1000*(data/(2^10)-0.5)*3.3/1100;  
