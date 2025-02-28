%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             MVPA Beta Estimation                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script was used to estimate the linear model for each individual subject
% It includes model estimation + motion check using hte motion regressors (plots the motion for each run (8 in total)
% Dependign on the model of choice (see README), different betas are being
% estimated.

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% SET UP %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize SPM
spm('defaults', 'fmri')
spm_jobman('initcfg')

% Path to the data
studyPath = '/Volumes/Drive/Thesis/new_data/';

% Where to save the model specification
first_level = '/MVPA_first_level/';

% Session folders 
session = {'/addsub_1', '/addsub_2'};

% Run folders 
runs = {'/epi1/', '/epi2/', '/epi3/', '/epi4/'};
n_runs = numel(runs);

% Folders with functional images
fMRIpath = {{'/functional/addsub_1/epi1/', '/functional/addsub_1/epi2/','/functional/addsub_1/epi3', '/functional/addsub_1/epi4'};{'/functional/addsub_2/epi1', '/functional/addsub_2/epi2','/functional/addsub_2/epi3', '/functional/addsub_2/epi4'}};

% Subjects
subjectList = {'sub8','sub9','sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20','sub21','sub23','sub24','sub25','sub26','sub28'};
% Additional parameters
TRsecs = 1.8;
% duration = 1; % duration of the stimulus

n_subj = numel(subjectList);
sessions = {'S1', 'S2'};

models = {'untr1-unt2', 'tbt-train', 'train-untr2'};
% models = {'untr1-unt2'};
n_model = numel(models);


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% FEEDING THE BATCH %%%
%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%% MODEL SET UP %%%%%%%%
for m = 1:n_model
    for subj = 1:n_subj % loop on subjects
        % Creating a new directory to store the first level results
        matlabbatch = {};
        d = fullfile(studyPath, subjectList{subj});
        cd(d)
        if m == 1
        mkdir MVPA_first_level
        end 
        cd MVPA_first_level
        dir = strcat('MVPA_model_', models{m});
        mkdir(dir) 
        save = [studyPath, '/', subjectList{subj}, '/MVPA_first_level/', dir]; % where is the first level folder saved
    
            matlabbatch{1}.spm.stats.fmri_spec.dir = {save};
            matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
            matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TRsecs;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
            matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
            if m < 3
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
                        if m == 1 % model untr1 - untr2
                                ons = onset(condition & runs ==r) / 1000;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).name = ['Condition' num2str(1)] ;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).onset = ons; 
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).duration = 0;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).tmod = 0;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).orth = 1;
                        end 

                        if m == 2 % second model - tbt-untr, here specifying the TBT items from session one 
                                ons = onset((condition == 5 | condition == 6 | condition == 7 | condition == 8)  & runs ==r ) / 1000;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).name = ['Condition' num2str(1)] ;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).onset = ons; 
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).duration = 0;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).tmod = 0;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(1).orth = 1;
                             
                        end
                        % Get the functional files
                        fun_dir = [studyPath, subjectList{subj}, fMRIpath{s,1}{1,r}];
                        f = cellstr(spm_select('ExtFPList', fun_dir, '^way-vol_.*\.nii$', 1)); %% this needs to be changed to unsmooth data 
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).scans = f;
        
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).multi = {''};
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).regress = struct('name', {}, 'val', {});
        
                        % Get the motion regressors
                        rp = spm_select('FPList', fullfile(studyPath, subjectList{subj}, fMRIpath{s,1}{1,r}), '^rp_y-vol.*\.txt$');
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).multi_reg = cellstr(rp);
                        matlabbatch{1}.spm.stats.fmri_spec.sess(r).hpf = 128; 
                    end 
                 
                    % We need to change the assigning for the second session (s =
                    % 2) because we are combining both sesions into one analysis.
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
                        if m == 1 % model untr1 - untr2
                            ons = onset((condition == 9 | condition == 10 | condition == 11 | condition == 12) & runs ==r) / 1000;
                            matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).name = ['Condition' num2str(2)] ;
                            matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).onset = ons; 
                            matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).duration = 0;
                            matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).tmod = 0;
                            matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                            matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).orth = 1;
                        end 

                        if m == 2 % second model - tbt-untr
                                ons = onset((condition == 16 | condition == 17 | condition == 14 | condition == 15)  & runs ==r) / 1000;
                                x = [5,6,7,8];
                                l = x(r);
                                matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).name = ['Condition' num2str(2)] ;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).onset = ons; 
                                matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).duration = 0;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).tmod = 0;
                                matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                matlabbatch{1}.spm.stats.fmri_spec.sess(l).cond(1).orth = 1;
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
            else            
% This part of the script is used for model 3, which only takes data from
% the second session
                for r = 1:4 % loop on runs                 
                            logdir = fullfile(studyPath, subjectList{subj}, 'log_files/');
                            cd(logdir)
                            onsetfile = strcat('MVPA_onsets_S2_',subjectList{subj}, '.m');
                            run(onsetfile)
                            condition = all_cond;
                            runs = all_sess;
                            onset = all_onsets;
                                for c = 1:2 % conditions 
                                    if c == 1
                                    ons = onset((condition == 14 | condition == 15 | condition == 16 | condition == 17)  & runs ==r) / 1000;
                                    else 
                                    ons = onset((condition == 9 | condition == 10 | condition == 11 | condition == 12)  & runs ==r ) / 1000;
                                    end 
                                    a = [1,2];
                                    b = a(c);
                                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(b).name = ['Condition' num2str(b)] ;
                                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(b).onset = ons; 
                                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(b).duration = 0;
                                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(b).tmod = 0;
                                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(b).pmod = struct('name', {}, 'param', {}, 'poly', {});
                                    matlabbatch{1}.spm.stats.fmri_spec.sess(r).cond(b).orth = 1;
                                end
                            % Get the functional files
                            fun_dir = [studyPath, subjectList{subj}, fMRIpath{2,1}{1,r}];
                            f = cellstr(spm_select('ExtFPList', fun_dir, '^way-vol_.*\.nii$', 1)); %% this needs to be changed to unsmooth data 
                            matlabbatch{1}.spm.stats.fmri_spec.sess(r).scans = f;
            
                            matlabbatch{1}.spm.stats.fmri_spec.sess(r).multi = {''};
                            matlabbatch{1}.spm.stats.fmri_spec.sess(r).regress = struct('name', {}, 'val', {});
            
                            % Get the motion regressors
                            rp = spm_select('FPList', fullfile(studyPath, subjectList{subj}, fMRIpath{2,1}{1,r}), '^rp_y-vol.*\.txt$');
                            matlabbatch{1}.spm.stats.fmri_spec.sess(r).multi_reg = cellstr(rp);
                            matlabbatch{1}.spm.stats.fmri_spec.sess(r).hpf = 128; 
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
    spm_mat = [studyPath, subjectList{subj}, first_level, dir, '/SPM.mat'];
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {spm_mat};
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 1;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
        
    % Run batch n2 
    spm_jobman ('run', matlabbatch(2));
    end 
end 