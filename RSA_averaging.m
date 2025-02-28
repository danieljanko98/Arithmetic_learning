%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             RSA Averaging                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script averages all conditions within and between trials. It is
% important to note that since we are also interested in the between
% session similarities, we don't look at the diagonal data only.
% Additionally, the data on the diagonal cannot be simply averaged together
% because the represent different groups of stimuli over multiple runs and
% session, not just multiple runs. The first four runs (rows 1-16) correspond to the first session and the second
% four runs (rows 17-32) correspond to the second session. The respected
% conditions in each session correspond to the README document.

subjectList = {'sub8', 'sub9','sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20','sub21','sub23','sub24','sub25','sub26', 'sub28'};
ROIs = {'rleft_ips_ROI_functional_binary','rright_ips_ROI_functional_binary', 'rleft_hippocampus_ROI_functional_binary', 'rright_hippocampus_ROI_functional_binary', 'rright_angulgyr_ROI_functional_binary', 'rleft_angulgyr_ROI_functional_binary'};
n_ROIs = numel(ROIs);
n_subj = numel(subjectList);
studyPath = '/Volumes/Drive/Thesis/new_data/';
secondLevel_folder = '/RSA_second_level/';


%figure; heatmap(tril(1-results.other.output{1}(1:8,1:8)), 'Colormap', jet); title('Correlations between conditions for run1, left M1 ROI');
for subj = 1:n_subj

    for roi =1:n_ROIs
        results = [studyPath, subjectList{subj}, secondLevel_folder, ROIs{roi}, '/res_other.mat'];
        load(results);
        data = cell(8,8);

        for j = 1:4
            for i = 1:4
            data{i,j} = mean(diag(1-abs(results.other.output{1}(i:4:16,j:4:16))));
            end 
        end
        
        for j = 1:4
            for i = 1:4
            data{(i+4),(j+4)} = mean(diag(1-abs(results.other.output{1}((i + 16):4:end,(j + 16):4:end))));
            end 
        end
        
        for j = 1:4
            for i = 1:4
            data{(i+4),j} = mean(diag(1-abs(results.other.output{1}((i + 16):4:end,j:4:16))));
            end 
        end
        
        for j = 1:4
            for i = 1:4
            data{i,j+4} = mean(diag(1-abs(results.other.output{1}(i:4:end,(j + 16):4:end))));
            end 
        end
        output_folder = [studyPath, subjectList{subj}, secondLevel_folder, ROIs{roi}, '/'];
        output_name = fullfile(output_folder, "averaged_results.mat");
        save(output_name, "data");
    end 
end 

%data = cell2mat(data);
%figure; 
%heatmap(tril(data(1:16,1:16)), 'Colormap', jet)
for roi = 1:n_ROIs
    data = cell(1, numel(n_subj));
    for subj = 1:n_subj 
        filePath = fullfile(studyPath, subjectList{subj}, secondLevel_folder, ROIs{roi}, "/averaged_results.mat");
        loadedData = load(filePath);
        data{subj} = loadedData;
    end 
    average_data = cell(8,8);
    for a = 1:8
        for b = 1:8
            average_data{a,b} = mean(cellfun(@(x) x.data{a,b}, data));
        end 
    end
    output_folder = [studyPath, 'RSA_group_level/'];
    name = [ROIs{roi} '.mat'];
    output_name = fullfile(output_folder, name);
    save(output_name, "average_data");
end


