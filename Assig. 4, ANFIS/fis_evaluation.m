
clc;    % Clear the command window
clear;  % Clear all variables from the workspace

% Load the FIS from a file
fis = readfis('Temperature_Control.fis');

% Range for Temperature Error (TE)
TE_range = -10:0.1:10;  % Define TE range from -10 to 10 in steps of 0.1

% Fixed Rate of Temperature Change (RTC)
fixed_RTC = 5;  % Fixed RTC at -5

% Preallocate the HC results array for speed
HC_results = zeros(size(TE_range));

% Evaluate the FIS for each TE value while keeping RTC fixed
for i = 1:length(TE_range)
    TE_value = TE_range(i);               % Get the current TE value
    input_values = [TE_value, fixed_RTC];  % Combine TE and fixed RTC into input array
    HC_results(i) = evalfis(fis, input_values);  % Evaluate the FIS
end

% Plot the results
figure;  % Create a new figure window
plot(TE_range, HC_results, 'LineWidth', 3);  % Plot HC vs. TE with a line width of 3
title('Heater Control Output vs. Temperature Error');  % Add a title
xlabel('Temperature Error (TE) [°C]');  % Add x-axis label
ylabel('Heater Control (HC) [%]');  % Add y-axis label
grid on;  % Enable grid for easier reading

clc;    % Clear the command window
clear;  % Clear all variables from the workspace

% Load the FIS from a file
fis = readfis('Temperature_Control.fis');

% Specific Temperature Error (TE) values
TE_values = [-10, -5, 5, 10];

% Range for Rate of Temperature Change (RTC)
RTC_range = -5:0.1:5;  % Define RTC range from -5 to 5 in steps of 0.1

% Preallocate the HC results matrix for speed
HC_results = zeros(length(TE_values), length(RTC_range));  

% Evaluate the FIS for each TE value across the entire RTC range
for i = 1:length(TE_values)
    for j = 1:length(RTC_range)
        TE_value = TE_values(i);              % Get the current TE value
        RTC_value = RTC_range(j);             % Get the current RTC value
        input_values = [TE_value, RTC_value]; % Combine TE and RTC into input array
        HC_results(i, j) = evalfis(fis, input_values);  % Evaluate the FIS
    end
end

% Plot the results for each TE value
figure;  % Create a new figure window
hold on; % Hold on to the current figure
colors = ['r', 'g', 'b', 'k']; % Define colors for each line

% Loop to plot each line
for i = 1:length(TE_values)
    plot(RTC_range, HC_results(i, :), 'LineWidth', 2, 'Color', colors(i)); 
end

% Customize the plot
title('Heater Control Output vs. Rate of Temperature Change for Different TE values');
xlabel('Rate of Temperature Change (RTC) [°C/min]');
ylabel('Heater Control (HC) [%]');
legend(arrayfun(@(x) sprintf('TE = %d°C', x), TE_values, 'UniformOutput', false));
grid on;  % Enable grid for easier reading
hold off; % Release the figure
%% a

clc;    % Clear the command window
clear;  % Clear all variables from the workspace

% Load the FIS from a file
fis = readfis('Temperature_Control.fis');

% Range for Temperature Error (TE)
TE_range = -10:0.1:10;  % Define TE range from -5 to 5 in steps of 0.1

% Specific Rate of Temperature Change (RTC) values
RTC_values = [-5, -2, 2, 5];

% Preallocate the HC results matrix for speed
HC_results = zeros(length(RTC_values), length(TE_range));

% Evaluate the FIS for the specific RTC values across the entire TE range
for i = 1:length(RTC_values)
    for j = 1:length(TE_range)
        RTC_value = RTC_values(i);            % Get the current RTC value
        TE_value = TE_range(j);               % Get the current TE value
        input_values = [TE_value, RTC_value]; % Combine TE and RTC into input array
        HC_results(i, j) = evalfis(fis, input_values);  % Evaluate the FIS
    end
end

% Plot the results for each RTC value
figure;  % Create a new figure window
hold on; % Hold on to the current figure
colors = ['r', 'g', 'b', 'k']; % Define colors for each line

% Loop to plot each line
for i = 1:length(RTC_values)
    plot(TE_range, HC_results(i, :), 'LineWidth', 2, 'Color', colors(i)); 
end

% Customize the plot
title('Heater Control Output vs. Temperature Error for Different RTC values');
xlabel('Temperature Error (TE) [°C]');
ylabel('Heater Control (HC) [%]');
legend(arrayfun(@(x) sprintf('RTC = %d°C/min', x), RTC_values, 'UniformOutput', false));
grid on;  % Enable grid for easier reading
hold off; % Release the figure
