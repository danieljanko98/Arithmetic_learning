function theoretical_models = loadTheoreticalModels(modelPath, models)
    % Load multiple theoretical models from CSV files
    % Inputs:
    %   modelPath - Path to the folder containing CSV files
    %   models - Cell array of model filenames (without .csv extension)
    % Output:
    %   theoretical_models - Cell array containing loaded model data

    numModels = length(models); % Get the number of models
    theoretical_models = cell(1, numModels); % Preallocate cell array

    for i = 1:numModels
        filePath = fullfile(modelPath, strcat(models{i}, '.csv')); % Construct file path
        theoretical_models{i} = load(filePath); % Load CSV file
    end
end