%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             MVPA Decoding                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% This scripts runs an MVPA decoder using three differetn models in 6
% regions of interest. The ouput are decodability ratings between two
% conditions (dependnign on the model) in each of the ROIs
% Script adapted from the decodign toolbox 

subjectList = {'sub8', 'sub9','sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20','sub21','sub23','sub24','sub25','sub26', 'sub28'};
models = {'MVPA_model_untr1-unt2', 'MVPA_model_tbt-train', 'MVPA_model_train-untr2'};
ROIs = {'left_ips','right_ips', 'left_hippocampus', 'right_hippocampus', 'left_angulgyr', 'right_angulgyr'};
n_ROIs = numel(ROIs);
n_model = numel(models);
n_subj = numel(subjectList);
studyPath = '/Volumes/Drive/Thesis/new_data/';
first_level = '/1stLevel';

for m = 1:n_model
  for r = 1:n_ROIs
    for subj = 1:n_subj
        d = fullfile(studyPath, subjectList{subj});
        if m == 1
        cd(d)
        mkdir MVPA_second_level 
        end 
        d = fullfile(studyPath, subjectList{subj}, 'MVPA_second_level');
        cd(d)
        s = models{m};
        mkdir(s)
        cd (s)
        l = ROIs{r};
        mkdir(l) 
        % Set defaults
        cfg = decoding_defaults;
        
        % Set the analysis that should be performed (default is 'searchlight')
        cfg.analysis = 'ROI'; % standard alternatives: 'wholebrain', 'ROI' (pass ROIs in cfg.files.mask, see below)
        cfg.searchlight.radius = 3; % use searchlight of radius 3 (by default in voxels), see more details below
        
        % Set the output directory where data will be saved, e.g. 'c:\exp\results\buttonpress'
        dir1 = fullfile(studyPath, subjectList{subj}, 'MVPA_second_level', models{m}, ROIs{r});
        cfg.results.dir = dir1;
        
        % Set the filepath where your SPM.mat and all related betas are, e.g. 'c:\exp\glm\model_button'
        dir = fullfile(studyPath, subjectList{subj}, 'MVPA_first_level', models{m});
        beta_loc = dir;
        % Set the filename of the ROI        
        n = ['r', ROIs{r}, '_ROI_functional2_binary.nii'];
        mask = fullfile(studyPath, subjectList{subj}, 'functional_masks/', n);
        cfg.files.mask = mask;
        
        % Set the label names to the regressor names which you want to use for 
        % decoding, e.g. 'button left' and 'button right'
        % don't remember the names? -> run display_regressor_names(beta_loc)
        % infos on '*' (wildcard) or regexp -> help decoding_describe_data
        labelname1  = 'Condition1';
        labelname2  = 'Condition2';
        
        labelvalue1 = 1; % value for labelname1
        labelvalue2 = -1; % value for labelname2
        
       
        cfg.verbose = 0; % you want all information to be printed on screen
 
        
        % Enable scaling min0max1 (otherwise libsvm can get VERY slow)
        % if you dont need model parameters, and if you use libsvm, use:
        cfg.scale.method = 'min0max1';
        cfg.scale.estimation = 'all'; % scaling across all data is equivalent to no scaling (i.e. will yield the same results), it only changes the data range which allows libsvm to compute faster

        cfg.plot_selected_voxels = 0; % 0: no plotting, 1: every step, 2: every second step, 100: every hundredth step...

        
        cfg.results.output = {'confusion_matrix'}; % 'accuracy_minus_chance' by default

        
        % A standard leave-one-run out cross validation analysis.
        
        % The following function extracts all beta names and corresponding run
        % numbers from the SPM.mat
        regressor_names = design_from_spm(beta_loc);
        
        % Extract all information for the cfg.files structure (labels will be [1 -1] if not changed above)
        cfg = decoding_describe_data(cfg,{labelname1 labelname2},[labelvalue1 labelvalue2],regressor_names,beta_loc);
        
        % This creates the leave-one-run-out cross validation design:
        cfg.design = make_design_cv(cfg); 
        cfg.design.unbalanced_data ='ok';
        cfg.results.overwrite = 1;
        % Run decoding
        results = decoding(cfg);
    end
  end 
end