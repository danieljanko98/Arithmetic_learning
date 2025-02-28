%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Second-level Univariate                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% This script was used for the 2nd level analysis. Variable 'dir' needs to be changed manually to represent what contrast we are using. 
% I was alos chnanging the spmT file number to correspond to whatever contrast I am using (the number of different contrasts is specififed 
% in the excel spreadsheet). Here we get a group effect of specified
% contrasts. Not automatized as the number of contrats is large and we
% don;t always need to take all of them. 

% cd('/Volumes/Drive/Thesis/new_data/') % Where to store the second level folder
% mkdir('second_level_GLM')
cd('/Volumes/Drive/Thesis/new_data/second_level_GLM')
dir = 'subtrainnoncar-subunnocar2'; % contrast specification 
mkdir(dir)
dir1 = fullfile('/Volumes/Drive/Thesis/new_data/second_level_GLM/',dir);
matlabbatch{1}.spm.stats.factorial_design.dir = {dir1};
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = {
                                                          '/Volumes/Drive/Thesis/new_data/sub8/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub9/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub10/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub11/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub14/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub15/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub16/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub17/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub18/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub19/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub20/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub21/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub23/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub24/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub25/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub26/1stLevel/spmT_0058.nii,1'
                                                          '/Volumes/Drive/Thesis/new_data/sub28/1stLevel/spmT_0058.nii,1'
                                                          }; % spmT file corresponding to the selected contrats (see the contrast spreadsheet for number specification)
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

spm_jobman('run', matlabbatch(1))
mat = fullfile('/Volumes/Drive/Thesis/new_data/second_level_GLM/',dir, '/SPM.mat');
matlabbatch{2}.spm.stats.fmri_est.spmmat = {mat};
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

spm_jobman('run', matlabbatch(2))