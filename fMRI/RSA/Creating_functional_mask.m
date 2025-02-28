%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      Creating functional masks                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% In this script, we create functional masks for each subject and each ROI
% based on individual activation patterns. An all-inclusive contrast from
% the firs-level model is used to assess which voxels respond durign the
% task. All active voxels are taken. The activity maps are overlayed on
% anatomical masks that were extartced beforehand. The voxels that belong
% to both of the maps are included in the final functional mask.

% Initialize SPM
spm('defaults', 'fmri')
spm_jobman('initcfg')

% Path to the data
studyPath = '/Volumes/Drive/Thesis/new_data/';
first_level = '/RSA_first_level';
maskPath = '/Volumes/Drive/Thesis/new_data/masks';
% Subjects
subjectList = {'sub8','sub9','sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20','sub21','sub23','sub24','sub25','sub26', 'sub28'};
%subjectList = {'sub8'};

n_subj = numel(subjectList);
ROIs = {'rleft_ips_ROI','rright_ips_ROI', 'rleft_hippocampus_ROI', 'rright_hippocampus_ROI', 'rright_angulgyr_ROI', 'rleft_angulgyr_ROI'};



for subj = 1:n_subj
    spm_mat = fullfile(studyPath, subjectList{subj}, first_level, '/SPM.mat');
    load(spm_mat);
    for i = 1:6
        if i == 1
        a = [studyPath, subjectList{subj}];
        cd(a)
        mkdir functional_masks
        end 
        dof = SPM.xCon(1).eidf; % Effective interest DOF for contrast k
        resdof = SPM.xX.erdf;
        t_threshold = tinv(1 - 0.001, resdof);
        % Step 1: Define file paths
        tmap_path = fullfile(studyPath, subjectList{subj}, first_level);
        tmap_file = spm_select('ExtFPList',tmap_path,'^spmT_0001.nii$'); % Full path to the T-map file
        %roi_mask_file = spm_select('FPList','/Volumes/Drive/Thesis/new_data/masks/', '^rright_angulgyr_ROI.nii$'); 
        roi_mask_file = spm_select('FPList','/Volumes/Drive/Thesis/new_data/masks/', ['^' ROIs{i} '.nii$']);% Full path to the ROI mask file
        %tmap_file = '/Volumes/Drive/Thesis/new_data/sub9/1stLevel/spmT_0001.nii';       % Full path to the T-map file
        %roi_mask_file = 'image','/Volumes/Drive/Thesis/new_data/masks/rrAngGyr_ROI.nii'; % Full path to the ROI mask file
        %output_file = ['/Volumes/Drive/Thesis/new_data/', ROI{subj}, '_functional'];  % Output file path for the masked T-map
        
        % Step 2: Use SPM's ImCalc function to apply the mask
        inputs = {tmap_file; roi_mask_file}; % Combine inputs into a column cell array
        output_name = [ROIs{i}, '_functional.nii'];
        output_path = [studyPath, subjectList{subj}, '/functional_masks'];
        % Step 3: Set up ImCalc
        matlabbatch{1}.spm.util.imcalc.input = inputs;
        matlabbatch{1}.spm.util.imcalc.output = output_name; % Name of the output file
        matlabbatch{1}.spm.util.imcalc.outdir = {output_path}; % Directory for the output file
        matlabbatch{1}.spm.util.imcalc.expression = 'i1 .* (i2 > 0)'; % Apply the mask (i2 > 0 ensures only nonzero voxels are used)
        %matlabbatch{1}.spm.util.imcalc.expression = sprintf('(i1 > %.4f) .* (i2 > 0)', t_threshold);
        matlabbatch{1}.spm.util.imcalc.var = struct([]);
        matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
        matlabbatch{1}.spm.util.imcalc.options.mask = 0;
        matlabbatch{1}.spm.util.imcalc.options.interp = 1; % Interpolation (1 = trilinear)
        matlabbatch{1}.spm.util.imcalc.options.dtype = 16; % Output data type (16 = float)
        
        % Step 3: Run the job
        spm('Defaults', 'fMRI');
        spm_jobman('initcfg');
        spm_jobman('run', matlabbatch);
        
        % Step 4: Threshold the masked T-map
        % Open the resulting masked T-map in SPM to set thresholds and extract active voxels.
        disp('Masked T-map has been created.');
    end 
end 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      Binarizing Functional Masks                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For a better compliance with the Decoding Toolbox protocols, this part
% binarizes the created functional masks. Any value that is larger than 0
% is assigned 1. 

ROIs = {'rleft_ips_ROI_functional','rright_ips_ROI_functional', 'rleft_hippocampus_ROI_functional', 'rright_hippocampus_ROI_functional', 'rright_angulgyr_ROI_functional', 'rleft_angulgyr_ROI_functional'};
studyPath = '/Volumes/Drive/Thesis/new_data/';


for subj = 1:n_subj
    for m = 1:length(ROIs)
        % Load the functional mask image with metadata
        mask_path = fullfile(studyPath, subjectList{subj}, 'functional_masks', ROIs{m});
        nii = niftiread(mask_path);
        info = niftiinfo(mask_path);  % Get metadata
        
        % Convert all non-zero values to 1 (ensuring strict binary values)
        nii(nii ~= 0) = 1;
        nii = double(nii);  % Convert to double to avoid precision issues
        % Convert back to original data type (matching header)
        nii = cast(nii, class(niftiread(mask_path))); % Ensures correct datatype
        
        % Save the modified mask while preserving metadata

        output_path = [studyPath, subjectList{subj}, '/functional_masks/', ROIs{m}, '_binary.nii'];
        niftiwrite(nii, output_path, info);
        
        % Display message
        disp('Converted mask to strict binary (0 and 1) values.');
        disp(['Saved binary mask to: ', output_path]);
    end 
end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      Transforming .nii to .img                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% To satisfy the Decoding Toolbox's input format requirements, this part
% is transforming .nii masks into .img

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
