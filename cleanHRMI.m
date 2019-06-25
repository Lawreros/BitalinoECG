% BETA program to clean up HRMI data by combining inaccurate short intervals,
% splitting inaccurate long intervals, averaging successive intervals that 
% are too short / too long by the same value, etc.
%
% Consider starting an artifact rejection algorithm from scratch for the 
% Student or others like him.


function [hrmi] = cleanHRMI(hrmi)

%% clean up RR intervals
hrmi.rrIntOriginal = hrmi.rrInt;
hrmi.rrMillisOriginal = hrmi.rrMillis;


%% 1) will need to come up with a strategy to deal with missing blocks of data

% TO DO: need an automated way to deal with gaps between received int's
% difference between successive millis values are quantized at ~ multiples
% of 250 ms + ~ 50 ms from draw loop of processing script.

hrmi.gapIntStart = [];

diffMillis = diff(hrmi.rrMillis);
for i = 1:length(diffMillis)
    
    % compare this rrMillis interval vs. running average of up to 10 recent intervals
    % (fewer at start of recording, but that should be OK)
    % if longer than minLongMillis (e.g. 1.5x) then mark as start of a gap
    
    % define indices to use for averaging recent
    % diffMillis that excludes bad intervals subsequently identified
    useInd = setdiff([max(1,i-9):i],hrmi.gapIntStart);
    
    if diffMillis(i)./mean(diffMillis(useInd)) > hrmi.minLongMillis
        
        hrmi.gapIntStart(end+1) = i;
        
    end
end

hrmi.gapIntExclude = sort(unique([hrmi.gapIntStart, hrmi.gapIntStart+1]));
hrmi.gapIntExcludeOriginal = hrmi.gapIntExclude;

% TO DO: add diagnostic plot here

%% 2) Sum 2, 3, or 4 intervals to 1, 1, or 2 intervals


%% 2a) 4 short interval to average into 2 intervals
num4to2Rep = 0;
useLength = length(hrmi.rrInt);
for i = 1:useLength
    
    % if there are five more intervals in data set, accounting for
    % replacements made in this loop
    if i < (useLength - 5 - (num4to2Rep*2))
        
        if all(hrmi.rrInt(i+1:i+4) < hrmi.addIntMax)       % if all 4 ahead < addIntMax
            
            if ~any(ismember([i:i+4], hrmi.gapIntExclude))   % if no gapStart in next 4
                
                comb4To2 = (sum(hrmi.rrInt(i+1:i+4))/2);
                if (abs((comb4To2./hrmi.rrInt(i))-1) < hrmi.minDiffAvg) &&...
                        (abs((comb4To2./hrmi.rrInt(i+5))-1) < hrmi.minDiffAvg)
                    % if sum(all 4 ahead)/2 within maxPctDiffAvg pct of good int before, after
                    num4to2Rep = num4to2Rep + 1;
                    
                    % now do the averaging, replacing in hrmi.rrInt and
                    % rrMillis, adjust hrmi.gapIntExclude
                    hrmi.rrInt = [hrmi.rrInt(1:i), comb4To2, comb4To2, hrmi.rrInt(i+5:end)];
                    
                    hrmi.rrMillis = [hrmi.rrMillis(1:i), hrmi.rrMillis(i)+((hrmi.rrMillis(i+5)-hrmi.rrMillis(i))/3),...
                        hrmi.rrMillis(i)+((hrmi.rrMillis(i+5)-hrmi.rrMillis(i))*2/3), hrmi.rrMillis(i+5:end)];
                    
                    % shift hrmi.gapIntExclude back by two for those falling
                    % after this corrected period
                    gapToShift = find(hrmi.gapIntExclude > (i+4));
                    hrmi.gapIntExclude(gapToShift) = hrmi.gapIntExclude(gapToShift) - 2;
                end
            end
        end
    end
end

%% plot results of this part of cleaning algorithm
if hrmi.doPlot == 1
    figure
    hold on
    plot(hrmi.rrMillisOriginal, hrmi.rrIntOriginal,'co-', 'linewidth',1.5)
    plot(hrmi.rrMillis, hrmi.rrInt,'bo-', 'linewidth',1.5)
    
    hx = xlabel('Millis (ms)');
    hy = ylabel('Interval (ms)');
    ht = title([hrmi.file, ' intervals']);
    
    formataxes
    set(gcf,'position',[ 1822          39        1616         520], 'paperpositionmode','auto')
    
    if hrmi.doPrint == 1
        % check for figures directory
        if ~isdir(hrmi.figsDir)
            mkdir(hrmi.figsDir)
        end
        
        print(gcf,[hrmi.figsDir,hrmi.file(1:end-4),'replace4to2.jpg'],'-djpeg')        
    end
end

%% 2b) 3 short interval to average into 1 interval
useLength = length(hrmi.rrInt);
num3to1Rep = 0;
for i = 1:useLength
    
    % if there are four more intervals in data set, accounting for
    % replacements made in this loop
    if i < (useLength - 4 - (num3to1Rep*3))
        
        if all(hrmi.rrInt(i+1:i+3) < hrmi.addIntMax)       % if all 3 ahead < addIntMax
            
            if ~any(ismember([i:i+3], hrmi.gapIntExclude))   % if no gapStart in next 3
                
                comb3To1 = sum(hrmi.rrInt(i+1:i+3));
                
                if (abs((comb3To1./hrmi.rrInt(i))-1) < hrmi.minDiffAvg) &&...
                        (abs((comb3To1./hrmi.rrInt(i+4))-1) < hrmi.minDiffAvg)
                    % if sum(all 3 ahead) within maxPctDiffAvg pct of good int before, after
                    num3to1Rep = num3to1Rep + 1;
                    
                    % now do the averaging, replacing in hrmi.rrInt and rrMillis
                    hrmi.rrInt = [hrmi.rrInt(1:i), comb3To1, hrmi.rrInt(i+4:end)];
                    hrmi.rrMillis = [hrmi.rrMillis(1:i), ...
                        hrmi.rrMillis(i)+((hrmi.rrMillis(i+4)-hrmi.rrMillis(i))/2), hrmi.rrMillis(i+4:end)];
                    
                    % shift hrmi.gapIntExclude back by two for those falling
                    % after this corrected period
                    gapToShift = find(hrmi.gapIntExclude > (i+3));
                    hrmi.gapIntExclude(gapToShift) = hrmi.gapIntExclude(gapToShift) - 2;
                end
            end
        end
    end
end

%% plot results of this part of cleaning algorithm
if hrmi.doPlot == 1
    figure
    hold on
    plot(hrmi.rrMillisOriginal, hrmi.rrIntOriginal,'co-', 'linewidth',1.5)
    plot(hrmi.rrMillis, hrmi.rrInt,'bo-', 'linewidth',1.5)
    
    hx = xlabel('Millis (ms)');
    hy = ylabel('Interval (ms)');
    ht = title([hrmi.file, ' intervals']);
    
    formataxes
    set(gcf,'position',[ 1822          39        1616         520], 'paperpositionmode','auto')
    
    if hrmi.doPrint == 1
        % check for figures directory
        if ~isdir(hrmi.figsDir)
            mkdir(hrmi.figsDir)
        end
        
        print(gcf,[hrmi.figsDir,hrmi.file(1:end-4),'replace3to1.jpg'],'-djpeg')
        
    end
end

%% 2c) 2 short interval to average into 1 interval
useLength = length(hrmi.rrInt);
num2to1Rep = 0;
for i = 1:useLength
    
    % if there are four more intervals in data set, accounting for
    % replacements made in this loop
    if i < (useLength - 3 - (num2to1Rep*2))
        
        if all(hrmi.rrInt(i+1:i+2) < hrmi.addIntMax)       % if all 2 ahead < addIntMax
            
            if ~any(ismember([i:i+2], hrmi.gapIntExclude))   % if no gapStart in next 2
                
                comb2To1 = sum(hrmi.rrInt(i+1:i+2));
                
                if (abs((comb2To1./hrmi.rrInt(i))-1) < hrmi.minDiffAvg) &&...
                        (abs((comb2To1./hrmi.rrInt(i+3))-1) < hrmi.minDiffAvg)
                    % if sum(all 2 ahead) within maxPctDiffAvg pct of good int before, after
                    
                    num2to1Rep = num2to1Rep + 1;
                    
                    % now do the averaging, replacing in hrmi.rrInt and hrmi.rrMillis
                    hrmi.rrInt = [hrmi.rrInt(1:i), comb2To1, hrmi.rrInt(i+3:end)];
                    hrmi.rrMillis = [hrmi.rrMillis(1:i), ...
                        hrmi.rrMillis(i)+((hrmi.rrMillis(i+3)-hrmi.rrMillis(i))/2), hrmi.rrMillis(i+3:end)];
                    
                    % shift hrmi.gapIntExclude back by two for those falling
                    % after this corrected period
                    gapToShift = find(hrmi.gapIntExclude > (i+2));
                    hrmi.gapIntExclude(gapToShift) = hrmi.gapIntExclude(gapToShift) - 1;
                end
            end
        end
    end
end


%% plot results of this part of cleaning algorithm
if hrmi.doPlot == 1
    figure
    hold on
    plot(hrmi.rrMillisOriginal, hrmi.rrIntOriginal,'co-', 'linewidth',1.5)
    plot(hrmi.rrMillis, hrmi.rrInt,'bo-', 'linewidth',1.5)
    
    hx = xlabel('Millis (ms)');
    hy = ylabel('Interval (ms)');
    ht = title([hrmi.file, ' intervals']);
    
    formataxes
    set(gcf,'position',[ 1822          39        1616         520], 'paperpositionmode','auto')
    
    if hrmi.doPrint == 1
        % check for figures directory
        if ~isdir(hrmi.figsDir)
            mkdir(hrmi.figsDir)
        end
        
        print(gcf,[hrmi.figsDir,hrmi.file(1:end-4),'replace2to1.jpg'],'-djpeg')
        
    end
end


%% 3a) Average one long and one short interval
% find abs(diff(hrmi.rrInt)) > 100 & diff(ints) immediately before and after > or <
% than zero as appropriate (but not > int I am working with)

diffInt = diff(hrmi.rrInt);
bigDiffInt = find(abs(diffInt) > 100);

badInt = [];

for i = 1:length(bigDiffInt)
    % skip very first part of recording and very end
    if (bigDiffInt(i) > 3) && (bigDiffInt(i) < (length(hrmi.rrInt)-2))
        if  ((sign(diffInt(bigDiffInt(i)))*diffInt(bigDiffInt(i)-1)) < 0) &&...
                ((sign(diffInt(bigDiffInt(i)))*diffInt(bigDiffInt(i)+1)) < 0) &&...
                ((sign(diffInt(bigDiffInt(i)))*diffInt(bigDiffInt(i)-1)) > -abs(diffInt(bigDiffInt(i)))) &&...
                ((sign(diffInt(bigDiffInt(i)))*diffInt(bigDiffInt(i)+1)) > -abs(diffInt(bigDiffInt(i))))
            
            % exclude edge + 1 either side of interval gap
            if ~ismember(bigDiffInt(i)+1,hrmi.gapIntExclude) % add one bc diff shifts by one
                indexBadInt = bigDiffInt(i)+1;
                badInt(end+1) = indexBadInt; % add one bc diff shifts by one
                
                % now adjust intervals in hrmi.rrInt
                % no need to change hrmi.rrMillis or shift hrmi.gapIntExclude
                hrmi.rrInt(indexBadInt - 1:indexBadInt) = ones(1,2).*mean(hrmi.rrInt(indexBadInt - 1:indexBadInt));
                
            end
            
        end
    end
end

%% 4) Split one double interval into two shorter intervals of correct duration

useLength = length(hrmi.rrInt);
num1to2Rep = 0;
for i = 2:useLength % skip first interval bc require one before and after
    
    % check this interval if there is one after for comparison,
    % accounting for any split intervals completed already
    if i < (useLength - 1 + (num1to2Rep*2))
        
        if hrmi.rrInt(i) > hrmi.subIntMin       % if this int is too long ~ double interval
            
            if ~(ismember(i, hrmi.gapIntExclude))   % if not the start or end of a gap of intervals
                
                if (abs(((hrmi.rrInt(i)/2)./hrmi.rrInt(i-1))-1) < hrmi.minDiffAvg) &&...
                        (abs(((hrmi.rrInt(i)/2)./hrmi.rrInt(i+1))-1) < hrmi.minDiffAvg)
                    % if splitting this interval in two is less than minDiffAvg relative to intervals
                    % before and after it
                    
                    num1to2Rep = num1to2Rep + 1;
                    
                    % now do the splitting, replacing in hrmi.rrInt and rrMillis
                    hrmi.rrInt = [hrmi.rrInt(1:i-1), ones(1,2).*(hrmi.rrInt(i)/2), hrmi.rrInt(i+1:end)];
                    hrmi.rrMillis = [hrmi.rrMillis(1:i-1),...
                        hrmi.rrMillis(i-1)+((hrmi.rrMillis(i+1)-hrmi.rrMillis(i-1))./3),...
                        hrmi.rrMillis(i-1)+((hrmi.rrMillis(i+1)-hrmi.rrMillis(i-1))./3*2),...
                        hrmi.rrMillis(i+1:end)];
                    
                    % shift hrmi.gapIntExclude for those falling
                    % after this corrected period
                    gapToShift = find(hrmi.gapIntExclude > i);
                    hrmi.gapIntExclude(gapToShift) = hrmi.gapIntExclude(gapToShift) + 1;
                end
            end
        end
    end
end

%% plot results of this part of cleaning algorithm
if hrmi.doPlot == 1
    figure
    hold on
    plot(hrmi.rrMillisOriginal, hrmi.rrIntOriginal,'co-', 'linewidth',1.5)
    plot(hrmi.rrMillis, hrmi.rrInt,'bo-', 'linewidth',1.5)
    
    hx = xlabel('Millis (ms)');
    hy = ylabel('Interval (ms)');
    ht = title([hrmi.file, ' intervals']);
    
    formataxes
    set(gcf,'position',[ 1822          39        1616         520], 'paperpositionmode','auto')
    
    if hrmi.doPrint == 1
        % check for figures directory
        if ~isdir(hrmi.figsDir)
            mkdir(hrmi.figsDir)
        end
        
        print(gcf,[hrmi.figsDir,hrmi.file(1:end-4),'split1to2.jpg'],'-djpeg')
        
    end
end
%% 5) some final work to exclude bad intervals

%% TO DO: refine this section. just tossing 740 ms intervals etc.

% shortInts = find(hrmi.rrInt < hrmi.addIntMax);
% hrmi.gapIntExclude = sort([hrmi.gapIntExclude,[1:5],[length(hrmi.rrInt)-4:length(hrmi.rrInt)],shortInts]);
