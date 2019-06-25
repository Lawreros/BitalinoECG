% Loads  bitalino data from a txt file
%
%  inputs: 
%     bitalino (structure)
%         .useChannels - % Define channels to load (use string in bitalino txt header)
%         .dir - directory for Bitalino txt file
%         .file - filename for Bitalino txt file
%
%   outputs:
%     bitalino (structure)
%         .header (structure) - json decode of header row
%         .data (2D array) - columns are channels; rows are each timepoint


function [bitalino] = loadBitalino(bitalino)

% Bitalino text file has three header lines
headerlines = 3;

% Open text file and read header lines
fid = fopen([bitalino.dir,bitalino.file], 'r');
for i=1:headerlines
    allHeaders(i) = {fgetl(fid)};
end

useHeader = char(allHeaders{2}); % content of header in second row

% Deal with some odd bracket formatting
findOpenBrackets = findstr(useHeader, '{');
findClosedBrackets = findstr(useHeader, '}');

% Read json into header
% skip first level of json blob which has just mac address
bitalino.header = jsondecode(useHeader(findOpenBrackets(2):findClosedBrackets(end-1))); 

%% Find col of data to plot by name of each of 'useChannels'
dataCols = zeros(length(bitalino.useChannels),1); % text data will be read into this variable

for j = 1:length(bitalino.useChannels) % for each channel requested
    
    for i = 1:length(bitalino.header.column) % search header to find channels requested
        
        if findstr(bitalino.header.column{i},bitalino.useChannels{j})
            dataCols(j) = i; % which column to read later
            break
        end
    end
    
    % If requested channel not found
    if dataCols(j) == 0
        error(['Did not find data column for useChannel named ', bitalino.useChannels{j},' in bitHeader column labels'])
    end
end

%% Read each row of data for each channel into bitalino.data

bitalino.data = [];
thisRow = 0;        % increment this value for each row of data in the txt file
tic                 % for debugging; how long does text import take; can be deleted
while 1
    tline = fgetl(fid);             % read one line
    if ~ischar(tline), break, end   % this break will occur at end of file
    tlineSplit = strsplit(tline);   % split string for each row
    thisRow = thisRow + 1;          % increment row to read
    for j = 1:length(bitalino.useChannels) % read columns for channels requested
        bitalino.data(thisRow,j) = cellfun(@str2num,tlineSplit(dataCols(j))); % store data
    end
end
toc          % for debugging; how long does text import take; can be deleted
fclose(fid); % close file
