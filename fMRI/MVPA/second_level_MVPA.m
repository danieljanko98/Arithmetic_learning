%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            MVPA Second Level                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This script performs second-level analysis of MVPA decoding results. It
% averages the scores accoross models, subjects, and ROIs. It runs a t-test
% agains chance level for each ROI and model on the averaged data. 



subjectList = {'sub8', 'sub9','sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20','sub21','sub23','sub24','sub25','sub26', 'sub28'};
%subjectList = {'sub8'};
studyPath = '/Volumes/Drive/Thesis/new_data/';
models = {'MVPA_model_untr1-unt2', 'MVPA_model_tbt-train', 'MVPA_model_train-untr2'};
ROIs = {'left_ips','right_ips', 'left_hippocampus', 'right_hippocampus', 'left_angulgyr', 'right_angulgyr'};
n_ROIs = numel(ROIs);
n_model = numel(models);
n_subj = numel(subjectList);
studyPath1 = '/Volumes/Drive/Thesis/new_data/MVPA_corr';

decoding = cell(n_ROIs, n_model);
t_test = cell(n_ROIs, n_model);
for m = 1:n_model
    for r = 1:n_ROIs
        a = [];
        b = [];
        c = [];
        d = [];
        for subj = 1:n_subj
            x = fullfile(studyPath, subjectList{subj}, '/MVPA_second_level/', models{m}, ROIs{r});
            cd(x)
            load('res_confusion_matrix.mat')
            y = results.confusion_matrix.output{1};
            a(subj) = y(1);
            b(subj) = y(2);
            c(subj) = y(3);
            d(subj) = y(4);
            t_test{r,m} = {a,d}; 
        end 
        e = sum(a) / numel(a);
        f = sum(b) / numel(b);
        g = sum(c) / numel(c);
        h = sum(d) / numel(d);
        decoding{r,m} = (e+h) / 2;
        cd(studyPath1);
        filename1 = sprintf('a%s.csv', models{m});
        filename2 = sprintf('d%s.csv', models{m});
        csvwrite(filename1, a);
        csvwrite(filename2, d);
    end 
end

pi = cell(n_ROIs, n_model);
for t = 1:n_model
    for o = 1:n_ROIs
      f = t_test{o,t}{1};
      e = t_test{o,t}{2};
      [h, p, ci, stats] = ttest(f,50,'Tail', 'right');
      pi{o,t}{1} = [p, stats.tstat];
      [h, p, ci, stats] = ttest(e,50,'Tail', 'right');
      pi{o,t}{2} = [p,stats.tstat];
      g = (e+f) / 2;
      [h,p,ci,stats] = ttest(g,50,'Tail', 'right');
      pi{o,t}{3} = [p, stats.tstat];
    end 
end 

