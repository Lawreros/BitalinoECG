% Program to load, process, and plot Bitalino ECG data
%
% 1) Define variables including:
%     Bitalino filename (must use txt file output from Bitalino)
%     String identifier from Bitalino header to determine which channels to load
%     Channel descriptor that labels a channel as ECG (or other data type)
%     
% 2) Load or read in data
% 
% 3) Process ECG: high pass filter, Pan Tompkins to find R waves; beat times and intervals
% 
% 4) Save data if flagged
% 
% 5) Plot data and print to jpg, if flagged:
%     Plot high pass filtered ECG + red circle for identified R-wave peaks
%     Align beats plots with average


%%
clear all % clear variables
close all % close figures

%% Define variables

% struct for saving data
bitalino = struct([]);

% define directories
bitalino(1).dir = 'C:/bitalino/'; % where the bitalino data is
bitalino.figsDir = 'C:/bitalino/'; % where you want figures saved

% define filename
bitalino.file = 'opensignals_201602147546_2019-03-17_19-06-08.txt';

% Define channels to load (use string in bitalino txt header)
bitalino.useChannels = {'A2'};

% Bitalino channel descriptors
% Must use these standard abbreviations: 'ECG', 'EDA', 'ACC', 
%   'Resp'(respiration), 'Binary1' (or 'Binary2', etc. for buzzer or LED activation via openSignals) 
bitalino.channelDesc = {'ECG'};

bitalinoSave          = 0;   % 1 == save .mat file to avoid time consuming .txt file import in the future
bitalinoLoad          = 0;   % 1 == load .mat; otherwise (if == 0), then load from txt file
bitalinoPrint         = 0;   % 1 == print figs to .jpg

% ECG processing variables
bitalino.plotPanTompkins = 1;   % flag to plot or not plot (set it 1 to have a plot or set it zero not to see any plots
bitalino.hpCutoff = 0.75;       % high-pass cutoff for ECG filtering (Hz); 0.75 Hz works well generally
bitalino.befBeat = 500;         % time before and after R peak to plot (ms)

%% Clean up filename to use as plot title

fileTitle = bitalino.file(1:end-4);
findund = findstr(bitalino.file, '_');
for i = 1:length(findund)
    fileTitle(findund(i)) = ' ';
end

%% load or read in data
if bitalinoLoad == 1 % load .mat file
    load([bitalino.dir,bitalino.file(1:end-3),'mat'])
else % read txt file
    [bitalino] = loadBitalino(bitalino); 
end

%% process ECG: high pass filter, Pan Tompkins to find R wave peaks; beat times and intervals

[bitalino] = processBitalinoECG(bitalino);

%% save data if flagged

if bitalinoSave == 1 && bitalinoLoad == 0
    save([bitalino.dir,bitalino.file(1:end-3),'mat'],'bitalino')
end

%% Make some plots

%% Plot high pass filtered ECG + red circle for identified R-wave peaks
figure
plot(bitalino.xData,bitalino.ecgFilt,'k-','linewidth',1) % plot filtered ECG
hold on
plot(bitalino.xData(bitalino.qrsIndexFilt),bitalino.ecgFilt(bitalino.qrsIndexFilt),'ro') % plot R-wave peaks

ht = title([fileTitle,' hp filt beats']);
hx = xlabel('Time (s)');
hy = ylabel('ECG (mV)');
formataxes % make plot look good

set(gcf,'position',[157         142        1143         542], 'paperpositionmode','auto') % define plot dimensions

if bitalinoPrint == 1
    print(gcf,'-djpeg',[bitalino.figsDir,'filtPeaks_',bitalino.file(1:end-3),'jpg'])
end


%% Align beats plots with average

alignBeats = []; % use this variable to collect all heart beats aligned to R wave for averaging

figure
hold on

% skip first and last beat, 
% unlikely to have sufficient samples before and after for plot
for i = 2:length(bitalino.qrsIndexFilt)-1
    if bitalino.qrsIndexFilt(i)-(bitalino.befBeat/1000*bitalino.samplingRate) > 0 % only collect beats with sufficient samples before R peak
        alignBeats(end+1,:) = bitalino.ecgFilt(bitalino.qrsIndexFilt(i)-(bitalino.befBeat/1000*bitalino.samplingRate):...
            bitalino.qrsIndexFilt(i)+(bitalino.befBeat/1000*bitalino.samplingRate)); % collect waveform of this beat
        % plot this beats waveform
        plot([-bitalino.befBeat/1000*bitalino.samplingRate:bitalino.befBeat/1000*bitalino.samplingRate],...
            bitalino.ecgFilt(bitalino.qrsIndexFilt(i)-(bitalino.befBeat/1000*bitalino.samplingRate):...
            bitalino.qrsIndexFilt(i)+(bitalino.befBeat/1000*bitalino.samplingRate)),'k-')
    end
end

% plot the average ecg waveform, aligned to R wave peak
plot([-bitalino.befBeat/1000*bitalino.samplingRate:bitalino.befBeat/1000*bitalino.samplingRate],...
    mean(alignBeats),'r-','linewidth',2)

ht = title([fileTitle,' hp filt beats']);
hx = xlabel('Time (ms)');
hy = ylabel('ECG (mV)');
formataxes % make it look good

set(gcf,'position',[157         142        1143         542], 'paperpositionmode','auto') % define plot dimensions

if bitalinoPrint == 1
    print(gcf,'-djpeg',[bitalino.figsDir,'alignedBeats_',bitalino.file(1:end-3),'jpg'])
end
