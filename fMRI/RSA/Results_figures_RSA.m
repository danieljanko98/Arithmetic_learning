%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Printing Dissimilarity Matrix                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% In this script we  print the dissimialrity matrix that includes summed dissimilarities accross all ROIs.

ROIs = {'rleft_ips_ROI_functional_binary','rright_ips_ROI_functional_binary', 'rleft_hippocampus_ROI_functional_binary', 'rright_hippocampus_ROI_functional_binary', 'rright_angulgyr_ROI_functional_binary', 'rleft_angulgyr_ROI_functional_binary'};
n_ROIs = numel(ROIs);
studyPath = '/Volumes/Drive/Thesis/new_data/RSA_group_level/';

all = zeros(8,8);
for roi = 1:n_ROIs
    dataPath = [studyPath, ROIs{roi}, '.mat'];
    load(dataPath);
    average_data = cell2mat(average_data);
    all = all + average_data; 
end 
h = heatmap(tril(all), 'Colormap', jet);
h.Title = 'Dissimilarity accross all ROIs';
name = 'Dissimilarity_results.png';
path = fullfile(studyPath, name);
saveas(h.Parent, path);

