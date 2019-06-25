# BitalinoECG
Loads and analyzes data collected by Bitalino ECG leads (https://bitalino.com/en/hardware) and sent over bluetooth to a program
called OpenSignal. All that is required to run it is MATLAB 2012 and the pan tompkins algorithim function found here:
https://www.mathworks.com/matlabcentral/fileexchange/45840-complete-pan-tompkins-implementation-ecg-qrs-detector

Outputs several figures displaying the ECG data under different filtering parameters, QRS structures, as well as determining the time between
R waves/peaks.

Future Plans:
Refine process of finding R peaks, make figures clearer
