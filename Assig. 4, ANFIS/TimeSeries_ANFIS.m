%% IMPORT DARA and DIVIDE IT TO TEST,TRAIN, AND VALIDATION

clc;
clear;

% Load time series data from a MAT file
loadedData = load('TimeSeriesData.mat');
timeSeries = loadedData.x;

% Visualize the time series data
figure(2);
set(gcf, 'Position', [100, 100, 800, 400]); % Set the figure size ([left bottom width height])
plot(timeSeries, 'LineWidth', 2, 'Color', 'b'); % Plot with a thicker blue line
title('Time Series Data Driven Mackey-Glass Equation', 'FontSize', 14);
xlabel('Time (s)', 'FontSize', 12);
ylabel('x(t)', 'FontSize', 12);
xlim([0 1200]); % Set x-axis limits to only display up to 1200
set(gca, 'FontSize', 10); % Set font size for axes
grid on; % Add grid

% Define the delays for time series prediction
delays = [10, 5, 15, 25];

% Prepare data for time series prediction
[X, Y] = TimeSeries_Data(timeSeries, delays);
Y = Y'; % Transpose Y to get the correct dimension


% Define the split ratios for the dataset
trainRatio = 0.8;  % 80% of the data for training
valRatio = 0.1;   % 10% of the data for validation
testRatio = 0.1;  % 10% of the data for testing

% Randomly divide the data into train, validation, and test sets
numSamples = size(X, 1);
[trainInd, valInd, testInd] = dividerand(numSamples, trainRatio, valRatio, testRatio);

% Split the data into training, validation, and testing sets using the indices
X_train = X(trainInd, :);
y_train = Y(trainInd, :);

X_val = X(valInd, :);
y_val = Y(valInd, :);

X_test = X(testInd, :);
y_test = Y(testInd, :);

% Display the sizes of each dataset
disp(['Size of Training Data: ', mat2str(size(X_train))]);
disp(['Size of Validation Data: ', mat2str(size(X_val))]);
disp(['Size of Testing Data: ', mat2str(size(X_test))]);


%% Training, and Tune the FIS using ANFIS to perform time series prediction

clc
%%%% STEP 1: Use "grid partitioning", "subtractive clustering", or "fuzzy
%%%% c-means" to create initial FIS

% Set Options for Creating a Sugeno FIS
% Clustering Options: GridPartition, SubtractiveClustering, FCMClustering
ClusteringType = 'GridPartition'; % Clustering method

switch ClusteringType
    case 'GridPartition' % Only for Sugeno FIS
        %%% Number of input membership functions
        % Integers > 1 with length equal to the number of inputs
        NumMFs = [3 4 4 3];
        
        %%% Input membership function type
        % Character array or string array
        % MF Options: gbellmf, gaussmf, gauss2mf, trimf, trapmf, sigmf, dsigmf,
        % (continue) psigmf, zmf, pimf, smf
        InputMFs = ["trimf" "gaussmf" "gaussmf" "trimf"];
        % InputMFs = "gaussmf";
        
        %%% Output membership function type
        OutputMFs = 'linear'; % Options: constant, linear
        
        opt = genfisOptions(ClusteringType, ...
            'NumMembershipFunctions', NumMFs, 'InputMembershipFunctionType', InputMFs, ...
            'OutputMembershipFunctionType', OutputMFs);
        
    case 'SubtractiveClustering' % Only for Sugeno FIS
        %%% Range of influence of the cluster center, value in the range [0, 1]
        % Vector of Integers: Use different influence ranges for each input and output
        % Specifying a smaller range of influence usually creates more and smaller data clusters, producing more fuzzy rules.
        ClusterInfluenceRange = [0.15 0.15 0.15 0.15 0.15];
        
        %%% Squash factor
        % Squash factor for scaling the range of influence of cluster centers
        % A smaller squash factor reduces the potential for outlying points to be considered as part of a cluster, which usually creates more and smaller data clusters.
        SquashFactor = 0.8;
        
        %%% Acceptance ratio, value in the range [0, 1]
        % Fraction of the potential of the first cluster center, above which another data point is accepted as a cluster center
        % The acceptance ratio must be greater than the rejection ratio.
        AcceptRatio = 0.3;
        
        %%% Rejection ratio, value in the range [0, 1]
        % Fraction of the potential of the first cluster center, below which another data point is rejected as a cluster center
        RejectRatio = 0.05;
        
        opt = genfisOptions(ClusteringType, ...
            'ClusterInfluenceRange', ClusterInfluenceRange, ...
            'SquashFactor', SquashFactor, 'AcceptRatio', AcceptRatio, 'RejectRatio', RejectRatio);
        
    case 'FCMClustering' % For Sugeno FIS for ANFIS     
        % Number of clusters
        % When NumClusters is 'auto', the genfis estimates the number of clusters using subtractive clustering with a cluster influence range of 0.5
        NumClusters = 20; % Options: Positive integer (a number), 'auto'
        
        % Exponent for the fuzzy partition matrix, scalar greater than 1
        % Controls the amount of fuzzy overlap between clusters, with larger values indicating a greater degree of overlap.
        Exponent = 2.5;
        
        % Maximum number of iterations
        MaxNumIteration = 150;
        
        opt = genfisOptions(ClusteringType, ...
            'FISType', 'sugeno', 'NumClusters', NumClusters, ...
            'Exponent', Exponent, 'MaxNumIteration', MaxNumIteration);
end

% Create FIS based on defined options
tic
FIS = genfis(X_train, y_train, opt);
disp(['genfis runtime = ', num2str(toc)])

% Evaluate FIS
y_hat = evalfis(FIS, X_test);


% Sort data based on time
[timeVector, sortingIndex] = sort(testInd);
y_test_sorted = y_test(sortingIndex);

% Plot Results
figure(2)
subplot(311)
plot(sortingIndex, y_test_sorted, 'b*', ...
    'LineWidth', 1, 'DisplayName', 'True Output')
hold on
plot(sortingIndex, y_hat, 'g.', ...
    'LineWidth', 1, 'DisplayName', 'Raw FIS Output')
hold off
legend, title('Raw FIS Data')

%%%% STEP 2: Set ANFIS Options
% Maximum number of training epochs
EpochNumber = 30;

% Training error goal
ErrorGoal = 0;

% Initial training step size
% The training step size is the magnitude of each gradient transition in the parameter space.
InitialStepSize = 0.01;

% Step-size decrease rate, positive scalar less than 1
StepSizeDecreaseRate = 0.9;

% Step-size increase rate, scalar greater than 1
StepSizeIncreaseRate = 1.1;

% Validation data
ValidationData = [X_val, y_val];

% ANFIS Optimization method, 1: hybrid method; 0: backpropagation gradient descent
OptimizationMethod = 1;

opt = anfisOptions('InitialFIS', FIS, 'EpochNumber', EpochNumber, ...
    'ErrorGoal', ErrorGoal, 'InitialStepSize', ...
    InitialStepSize, 'StepSizeDecreaseRate', StepSizeDecreaseRate, ...
    'StepSizeIncreaseRate', StepSizeIncreaseRate, ...
    'ValidationData', ValidationData, 'OptimizationMethod', OptimizationMethod);

%%%% STEP 3: Optimize (train) FIS using ANFIS
tic
%opt = anfisOptions('InitialFIS',FIS,'ValidationData',ValidationData);
[FIS, trainError, stepSize, chkFIS, chkError] = anfis([X_train, y_train], opt);
disp(['ANFIS Training runtime = ', num2str(toc)])
% [FIS, trainError, stepSize] = anfis( ...
%     [Data.x_train, Data.y_train], opt); % Without Validation Data

% Evaluate FIS for Train Data
y_hat = evalfis(FIS, X_train);

% Plot Results for Train Data
figure(2)
subplot(312)
plot(trainInd, y_train, 'b*', ...
    'LineWidth', 1, 'DisplayName', 'True Output')
hold on
plot(trainInd, y_hat, 'ro', ...
    'LineWidth', 1, 'DisplayName', 'ANFIS Output')
hold off
legend, title('Train Data')


% Evaluate FIS for Test Data
y_hat = evalfis(FIS, X_test);

% Calculate RMSE for Test Data
testRMSE = sqrt(mean((y_test - y_hat).^2));
disp(['Test RMSE: ', num2str(testRMSE)]);
% Plot Results for Test Data
figure(2)
subplot(313)
hold on
plot(testInd, y_test, 'b*', ...
    'LineWidth', 1, 'DisplayName', 'True Output')
hold on
plot(testInd, y_hat, 'ro', ...
    'LineWidth', 1, 'DisplayName', 'ANFIS Output')
hold off
legend, title('Test Data')


figure(3)
plot(1:size(trainError), trainError, 'LineWidth', 2)
xlabel('Iterations (Epochs)')
ylabel('ANFIS Training Error')
