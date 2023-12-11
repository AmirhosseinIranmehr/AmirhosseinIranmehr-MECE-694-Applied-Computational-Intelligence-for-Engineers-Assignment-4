function [inputs, outputs] = TimeSeries_Data(x, delays)
    % TimeSeries_Data Function to prepare data for time series prediction

    % Initialize the maximum delay
    maxDelay = max(delays);

    % Initialize input and output arrays
    inputs = [];
    outputs = x(maxDelay+1:end); % Outputs are simply the values of x shifted by maxDelay

    % Construct input matrix based on delays
    for i = maxDelay+1:length(x)
        inputRow = []; % Initialize row for this input
        for d = delays
            inputRow = [inputRow, x(i-d)]; % Add delayed elements to the row
        end
        inputs = [inputs; inputRow]; % Add row to the inputs matrix
    end
end