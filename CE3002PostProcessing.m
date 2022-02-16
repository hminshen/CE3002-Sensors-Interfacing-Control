%Connect to Arduino
a = arduino;
pause(2)

figure
h = animatedline('Color',[0 .7 .7]);
g = animatedline('Color',[0 .5 .5]);
ax = gca;
ax.YGrid = 'on';
ax.YLim = [0 5];

startTime = datetime('now');
%initialize start time as 0
t = 0;
%first cycle to start at 3 seconds
k = 3;
p = 0;
%Empty arrays to hold location of peaks
A = double.empty(1,0);
B = double.empty(1,0);
j = seconds(k);
while t<seconds(30)
    % Read current voltage value
    v = readVoltage(a,'A1');
    % Get current time
    t =  datetime('now') - startTime;
    % Add points to animation
    addpoints(h,datenum(t),v)
    addpoints(g,datenum(t),v)
    % Update axes
    ax.XLim = datenum([t-seconds(15) t]);
    datetick('x','keeplimits')
    if t > j 
        [timeLogs,voltageLogs] = getpoints(g);
        v_max = max(voltageLogs);
        v_min = min(voltageLogs);
        %Finding an appropriate threshold value using max and min
        %points, to filter out the 2nd smaller peak
        v_threshold = ((v_max - v_min) * 0.7) + v_min;
        timeSecs = (timeLogs-timeLogs(1))*24*3600;
        %disp(v_threshold)
        %Finding location of peaks
        [peaks,indices] = findpeaks(voltageLogs,timeSecs,'MinPeakHeight',v_threshold);
        H2 = horzcat(A,indices + p);
        H3 = horzcat(B,peaks);
        A = H2;
        B = H3;
        p = datenum(t)*24*3600;
        %Calculate heartrate
        distances = mean(diff(indices));
        heartRate = 60 / distances;
        %disp('Average time between each heartbeat: ',distances)
        if heartRate > 0
            disp('Heart Rate: ',heartRate)
        end
        if heartRate > 80
            writeDigitalPin(a, 'D11', 1); %red LED lighted
            writeDigitalPin(a, 'D12', 0);
        else
            writeDigitalPin(a, 'D11', 0); 
            writeDigitalPin(a, 'D12', 1); %green LED lighted
        end
        clearpoints(g)
        k = k + 2; %take heartrate reading every 2 seconds
        j = seconds(k);
    end
    drawnow
end

%Plot the recorded data
[timeLogs,voltageLogs] = getpoints(h);
timeSecs = (timeLogs-timeLogs(1))*24*3600;
figure
plot(timeSecs,voltageLogs)
xlabel('Elapsed time (sec)')
ylabel('Voltage (V)')
distances = mean(diff(A));
heartRate = 60 / distances;
%disp('Average time between each heartbeat: ',distances)
if heartRate > 0
    disp('Heart Rate: ',heartRate)
end
%plot(timeSecs,voltageLogs,A,B,'o')
text(A, B, num2str((1:numel(A))'));
if heartRate > 80
    writeDigitalPin(a, 'D11', 1);
else
    writeDigitalPin(a, 'D13', 0);
end

% Save voltage results to a file
T = table(timeSecs',voltageLogs','VariableNames',{'Time_sec','Voltage Lvl'});
filename = 'Voltage_Time_Data.xlsx';
% Write table to file 
writetable(T,filename)
T2 = table(A',B','VariableNames',{'Peak_Time_sec','Peak Voltage Lvl'});
filename2 = 'Peaks_Data.xlsx';
% Write table to file 
writetable(T2,filename2)
% Print confirmation to command line
fprintf('Results table with %g voltage measurements saved to file %s\n',...
    length(timeSecs),filename)
clear a;