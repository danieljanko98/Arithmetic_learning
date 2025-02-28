%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      RSA Model Estimation                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script was used to estimate the linear model for each individual subject
% It includes model estimation + motion check using the motion regressors (plots the motion for each run (8 in total)

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% SET UP %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize SPM
spm('defaults', 'fmri')
spm_jobman('initcfg')

% Path to the data
studyPath = '/Volumes/Drive/Thesis/new_data/';

% Where to save the model specification
first_level = '/RSA_first_level/';

% Session folders 
session = {'/addsub_1', '/addsub_2'};

% Run folders 
runs = {'/epi1/', '/epi2/', '/epi3/', '/epi4/'};
n_runs = numel(runs);

% Folders with functional images
fMRIpath = {{'/functional/addsub_1/epi1/', '/functional/addsub_1/epi2/','/functional/addsub_1/epi3', '/functional/addsub_1/epi4'};{'/functional/addsub_2/epi1', '/functional/addsub_2/epi2','/functional/addsub_2/epi3', '/functional/addsub_2/epi4'}};

% Subjects
subjectList = {'sub8', 'sub9','sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20','sub21','sub23','sub24','sub25','sub26','sub28'};

% Additional parameters
TRsecs = 1.8;

n_subj = numel(subjectList);
sessions = {'S1', 'S2'};



%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FEEDING THE BATCH %%%
%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%% MODEL SET UP %%%%%%%%
    for subj = 1:n_subj % loop on subjects
        % Creating a new directory to store the first level results
        matlabbatch = {};
        d = fullfile(studyPath, subjectList{subj});
        cd(d)
        folder_name = 'RSA_first_level';

        if exist(folder_name, 'dir')
            cont = 0;
        else 
            cont = 1;
        end 
        if cont == 1 
            mkdir RSA_first_level
            cd RSA_first_level
            save = pwd; % where is the first level folder saved
        
            matlabbatch{1}.spm.stats.fmri_spec.dir = {save};
            matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
            matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TRsecs;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    
            for s = 1:2 % where is the session defined again? Look into univariate script 
              for r = 1:4 % loop on runs                 
                 if s == 1
                    logdir = fullfile(studyPath, subjectList{subj}, 'log_files/');
                    cd(logdir)
                    onsetfile = strcat('MVPA_onsets_S1_',subjectList{subj}, '.m');
                    run(onsetfile)
                    condition = all_cond;
                    runs = all_sess;
                    onset = all_onsets;
                    matrix = [condition; runs; onset];
                    i = 1;
                    for c = 1:4
                        indices = find(matrix(1, :) == i & matrix(2, :) == r);
                        ind = find(matrix(1, :) == i + 1 & matrix(2, :) == r);
                        ons = matrix(3, sort([indices, ind])) / 1000;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(c).name = ['Condition' num2str(c)] ;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(c).onset = ons; 
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(c).duration = 0;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(c).tmod = 0;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {});
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(c).orth = 1;
                        i = i + 2;

                    end 
                    % Get the functional files
                    fun_dir = [studyPath, subjectList{subj}, fMRIpath{s,1}{1,r}];
                    f = cellstr(spm_select('ExtFPList', fun_dir, '^way-vol_.*\.nii$', 1)); %% this now takes unsmooth data 
                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).scans = f;
                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).multi = {''};
                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).regress = struct('name', {}, 'val', {});
            
                    % Get the motion regressors
                    rp = spm_select('FPList', fullfile(studyPath, subjectList{subj}, fMRIpath{s,1}{1,r}), '^rp_y-vol.*\.txt$');
                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).multi_reg = cellstr(rp);
                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).hpf = 128; 
                 end 
                     
                 % We need to change the assigning for the second session (s =
                 % 2) because we are combining both sessions into one analysis.
                 % Additionally, the second session files use similar labels for
                 % conditions and sessions but they need to be assigned to
                 % different positions. We are leaving out condiiton 5 since it
                 % is the display of answer options
                 if s == 2 
                    x = [5,6,7,8];
                    l = x(r);
                    logdir = fullfile(studyPath, subjectList{subj}, 'log_files/');
                    cd(logdir)
                    onsetfile = strcat('MVPA_onsets_S2_', subjectList{subj}, '.m');
                    run(onsetfile)
                    condition = all_cond;
                    runs = all_sess;
                    onset = all_onsets;
                    matrix = [condition; runs; onset];
                    i = 9;
                    for c = 1:2
                        indices = find(matrix(1, :) == i & matrix(2, :) == r);
                        ind = find(matrix(1, :) == i + 1 & matrix(2, :) == r);
                        ons = matrix(3, sort([indices, ind])) / 1000;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).name = ['Condition' num2str(x(c))] ;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).onset = ons; 
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).duration = 0;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).tmod = 0;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {});
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).orth = 1;
                        i = i + 2;
                    end
                    
                    i = 14;
                    for c = 3:4
                        indices = find(matrix(1, :) == i & matrix(2, :) == r);
                        ind = find(matrix(1, :) == i + 1 & matrix(2, :) == r);
                        ons = matrix(3, sort([indices, ind])) / 1000;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).name = ['Condition' num2str(x(c))] ;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).onset = ons; 
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).duration = 0;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).tmod = 0;
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {});
                        matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(c).orth = 1;
                        i = i + 2;
                    end
                    %Get the functional files (we need to do it separately
                    %because the run number depends on the value of s -
                    %reasoning explained by 'y' above)
                    fun_dir = [studyPath, subjectList{subj}, fMRIpath{s,1}{1,r}];
                    f = cellstr(spm_select('ExtFPList', fun_dir, '^way-vol_.*\.nii$', 1)); %% This needs to be change to unsmooth data
                    matlabbatch{1}.spm.stats.fmri_spec.sess(l).scans = f;
            
                    matlabbatch{1}.spm.stats.fmri_spec.sess(l).multi = {''};
                    matlabbatch{1}.spm.stats.fmri_spec.sess(l).regress = struct('name', {}, 'val', {});
                    % Get the motion regressors
                            
                    rp = spm_select('FPList', fullfile(studyPath, subjectList{subj}, fMRIpath{s,1}{1,r}), '^rp_y-vol.*\.txt$');
                    matlabbatch{1}.spm.stats.fmri_spec.sess(l).multi_reg = cellstr(rp);
                    matlabbatch{1}.spm.stats.fmri_spec.sess(l).hpf = 128;
                 end 
               end 
             end                    
            matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
            matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
            matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
            matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
            matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
            matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
            matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
                
            % Run batch 1 
            spm_jobman ('run', matlabbatch(1));
            
            %%%%%%% ESTIMATE %%%%%%%%
            
            % Beta estimation
            spm_mat = [studyPath, subjectList{subj}, first_level, '/SPM.mat'];
            matlabbatch{2}.spm.stats.fmri_est.spmmat = {spm_mat};
            matlabbatch{2}.spm.stats.fmri_est.write_residuals = 1;
            matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
                
            % Run batch n2 
            spm_jobman ('run', matlabbatch(2));
        end 
    end 