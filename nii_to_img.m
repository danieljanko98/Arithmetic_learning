%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      Transforming .nii to .img                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% To satisfy the Decoding Toolbox's input format requirements, this part
% is transforming .nii masks into .img


subjectList = {'sub8', 'sub9','sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20','sub21','sub23','sub24','sub25','sub26', 'sub28'};
%subjectList = {'sub8'};
ROIs = {'rleft_ips_ROI_functional_binary','rright_ips_ROI_functional_binary', 'rleft_hippocampus_ROI_functional_binary', 'rright_hippocampus_ROI_functional_binary', 'rright_angulgyr_ROI_functional_binary', 'rleft_angulgyr_ROI_functional_binary'};
n_ROIs = numel(ROIs);
n_subj = numel(subjectList);
studyPath = '/Volumes/Drive/Thesis/new_data/';

for subj = 1:n_subj
    for m = 1:n_ROIs
        mask_folder = fullfile(studyPath, subjectList{subj}, 'functional_masks/');
        mask = spm_select('FPList', mask_folder, ['^' ROIs{m} '.nii']);
        matlabbatch{1}.spm.util.imcalc.input = {mask};
        output_name = [ROIs{m}, '.img'];
        matlabbatch{1}.spm.util.imcalc.output = output_name;
        matlabbatch{1}.spm.util.imcalc.outdir = {mask_folder};
        matlabbatch{1}.spm.util.imcalc.expression = 'i1';
        matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
        matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
        matlabbatch{1}.spm.util.imcalc.options.mask = 0;
        matlabbatch{1}.spm.util.imcalc.options.interp = 1;
        matlabbatch{1}.spm.util.imcalc.options.dtype = 16;
        
        spm_jobman ('run', matlabbatch(1));
    end 
end 
