% This code reslices images to have the same number of dimensions and be
% usable as masks
% Ref image = preprocessed functional image (e.g., sway... .nii)
% Source image = image to be resliced (e.g., generated ROI mask .nii)  

matlabbatch{1}.spm.spatial.coreg.write.ref = '<UNDEFINED>';
matlabbatch{1}.spm.spatial.coreg.write.source = '<UNDEFINED>';
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 4;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';