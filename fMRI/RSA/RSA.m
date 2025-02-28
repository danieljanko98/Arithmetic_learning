%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        RSA Model Fitting                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is a script for RSA. Here, we compare the similarity between 8
% different conditions. For what each condition corresponds to, see README
% file.

subjectList = {'sub8', 'sub9','sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20','sub21','sub23','sub24','sub25','sub26', 'sub28'};
%ROIs = {'rleft_ips_ROI_functional_binary','rright_ips_ROI_functional_binary', 'rleft_hippocampus_ROI_functional_binary', 'rright_hippocampus_ROI_functional_binary', 'rright_angulgyr_ROI_functional_binary', 'rleft_angulgyr_ROI_functional_binary'};
ROIs = {'rleft_ips_ROI_functional2_binary','rright_ips_ROI_functional2_binary', 'rleft_hippocampus_ROI_functional2_binary', 'rright_hippocampus_ROI_functional2_binary', 'rright_angulgyr_ROI_functional2_binary', 'rleft_angulgyr_ROI_functional2_binary'};
n_ROIs = numel(ROIs);
n_subj = numel(subjectList);
studyPath = '/Volumes/Drive/Thesis/new_data/';
first_level = '/RSA_1stLevel';

for r = 1:n_ROIs
    for subj = 1:n_subj
        d = fullfile(studyPath, subjectList{subj});
        if r == 1
        cd(d)
        mkdir RSA_second_level 
        end 
        d = fullfile(studyPath, subjectList{subj}, 'RSA_second_level');
        cd(d)
        l = ROIs{r};
        mkdir(l) 
        
        % Set defaults
        cfg = decoding_defaults;
        
        % Set the analysis that should be performed (default is 'searchlight')
        cfg.analysis = 'ROI';
        
        % Set the output directory where data will be saved, e.g. 'c:\exp\results\buttonpress'
        dir = fullfile(studyPath, subjectList{subj}, 'RSA_second_level', ROIs{r});
        cfg.results.dir = dir;
        
        % Set the filepath where your SPM.mat and all related betas are, e.g. 'c:\exp\glm\model_button'
        beta_dir = fullfile(studyPath, subjectList{subj}, 'RSA_first_level');
        beta_loc = beta_dir;
        
        % Set the filename of the ROI
        n = [ROIs{r}, '.img'];
        mask = fullfile(studyPath, subjectList{subj}, 'functional_masks/', n);
        cfg.files.mask = mask;
        
        labelnames = {'Condition1', 'Condition2', 'Condition3', 'Condition4', 'Condition5', 'Condition6', 'Condition7', 'Condition8'};
        
        % since the labels are arbitrary, we will set them randomly to -1 and 1
        labels(1:2:length(labelnames)) = -1;
        labels(2:2:length(labelnames)) =  1;
        
        
        % set everything to similarity analysis (for available options as model parameters, check decoding_software/pattern_similarity/pattern_similarity.m)
        cfg.decoding.software = 'similarity';
        cfg.decoding.method = 'classification';
        cfg.decoding.train.classification.model_parameters = 'pearson'; % this is pearson correlation
        
        cfg.results.output = 'other';
        
        
        cfg.verbose = 0; % you want all information to be printed on screen
        
        % Enable scaling min0max1 (otherwise libsvm can get VERY slow)
        % if you dont need model parameters, and if you use libsvm, use:
        cfg.scale.method = 'min0max1';
        cfg.scale.estimation = 'all'; % scaling across all data is equivalent to no scaling (i.e. will yield the same results), it only changes the data range which allows libsvm to compute faster
        
        % Decide whether you want to see the searchlight/ROI/... during decoding
        cfg.plot_selected_voxels = 0; % 0: no plotting, 1: every step, 2: every second step, 100: every hundredth step...
           
        % The following function extracts all beta names and corresponding run
        % numbers from the SPM.mat
        regressor_names = design_from_spm(beta_loc);
        
        % Extract all information for the cfg.files structure (labels will be [1 -1] )
        cfg = decoding_describe_data(cfg,labelnames,labels,regressor_names,beta_loc);
        
        % This creates a design in which all data is used to calculate the similarity
        cfg.plot_design = 0;
        cfg.design = make_design_similarity(cfg); 
        cfg.results.overwrite = 1;
        % Use the next line to use RSA with cross-validation
        % cfg.design = make_design_similarity_cv(cfg); 
        %cfg.design.unbalanced_data = 'ok';
        % Run decoding
        results = decoding(cfg);

    end 
end 