%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      RSA Model Comparison                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% In this script, we perfom comparison of RSA estimations to our
% theoretical models.
% Each mdoel is used as a regressor and the amount of explained variance is
% used to assess model's fit. All models are also evaluated using
% permutation testing. 10000 versions of randomly shuffled model are used
% and regressor and teh explained variance is  again plotted against the
% actual value of explained variance from the original model. The
% performance of any given model iss averaged accross all ROIs (same for
% permutations)

ROIs = {'rleft_ips_ROI_functional2_binary','rright_ips_ROI_functional2_binary', 'rleft_hippocampus_ROI_functional2_binary', 'rright_hippocampus_ROI_functional2_binary', 'rright_angulgyr_ROI_functional2_binary', 'rleft_angulgyr_ROI_functional2_binary'};
studyPath = '/Volumes/Drive/Thesis/new_data/RSA_group_level/';
names = {'Left_IPS', 'Right_IPS', 'Left_Hipp', 'Right_Hipp', 'Right_AG', 'Left_AG'};
models = {'Memory_session_model', 'Operation_session_model', 'Oper_optim_model', 'Session_model', 'Memory_model'};
modelPath = '/Users/danieljanko/Desktop/Projects/Arithmetic_learning/RSA/Theoretical_models';



theoretical_models = loadTheoreticalModels(modelPath, models);

Results_LM = table2cell(table());
Results_PT = table2cell(table());

for i = 1:5
    if i < 3
        model_vector = 4 - theoretical_models{i}(tril(true(8), -1));
         
    else
        model_vector = 2 - theoretical_models{i}(tril(true(8), -1));
    end 
    
    var_explained = [];
    for j = 1:6
        
        ROI_path = fullfile(studyPath, strcat(ROIs{j}, '.mat'));
        fMRI_dissimilarity_matrix = load(ROI_path); 
        fMRI_dissimilarity_matrix = fMRI_dissimilarity_matrix.average_data;
        PT = table2cell(table());
        %% LINEAR REGRESSION %% 
        
        % Vectorize the matrices (flatten upper triangle, excluding diagonal)
        fMRI_dissimilarity_vector = fMRI_dissimilarity_matrix(tril(true(8), -1));
    
        % Create a design matrix (predictors)
        X = model_vector;  % For the first model
      
        
        % Perform linear regression for both models
        mdl = fitlm(X, cell2mat(fMRI_dissimilarity_vector));  % Model 1

        
        Results_LM{1,i} = models{i};
        Results_LM{j+1, i} = [num2str(mdl.Rsquared.Ordinary), ', ', num2str(mdl.Coefficients{2,4})];
        var_explained(j) = mdl.Rsquared.Ordinary;
      
        %% Permutation Testing

        for k = 1:10000
            shuffled_vector = model_vector(randperm(length(model_vector)));
            mdl_PT = fitlm(shuffled_vector, cell2mat(fMRI_dissimilarity_vector));
            PT{k, j} = mdl_PT.Rsquared.Ordinary;
        end 

    end 

    %filename = sprintf('Permutation_testing_results_%s.csv', models{i});
    %writecell(Results_PT, filename);
    %vector_name = sprintf('Variance_explained_%s.csv', models{i});
    %writematrix(var_explained, vector_name);
    combined_data = [PT{:,:}];
    figure('Visible', 'off');
    histogram(combined_data)
    x_value = mean(var_explained);  
    % Add the vertical line at the specified x value
    xline(x_value, 'r', 'LineWidth', 2);  % 'r' for red, adjust LineWidth as needed
    % Set the filename for saving the figure as a PDF
    histname = sprintf('histogram_%s.pdf', models{i});
    % Save the current figure as a PDF
    saveas(gcf, histname);
    close(gcf);
    [h, p] = ttest(combined_data, x_value);
    Results_PT{1,i} = p;

end

Results_LM(2:end, 6) = names'; 
writecell(Results_LM, 'Linear_models_results.csv');

