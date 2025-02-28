%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Preprocessing - Artimetic Learning           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear all; 
close all; clc;

% Daniel Janko - 2025
% André Knops - March 2021
% preprocessing script using B0
% inspired by scripts from 
% 1) Department of Child and Adolescent Psychiatry and Psychotherapy, Psychiatric Hospital, University of Zurich, Switzerland Iliana Karipidis, September 2017
% 2) https://github.com/ilcb-crex/CREx_fMRI/blob/master/CREx_fMRI_Preprocessing_Prisma.m#L216

% the following steps are implemented:          
% Realign
% SliceTiming
% Coregister
% Segment
% Deformation
% Normalise
% Smooth


% Initialise SPM
spm('defaults','fmri');  
spm_jobman('initcfg');

%adjust path were all the needed data is stored
studyPath = '/Volumes/Drive/Thesis/new_data/'; % where your data are

%adjust folder name of task to be preprocessed
task = {'/addsub_1', '/addsub_2'};

%adjust folder name of functional images
fMRIpaths = {{'/functional/addsub_1/epi1/', '/functional/addsub_1/epi2/', '/functional/addsub_1/epi3', '/functional/addsub_1/epi4'};{'/functional/addsub_2/epi1', '/functional/addsub_2/epi2', '/functional/addsub_2/epi3', '/functional/addsub_2/epi4'}};



%adjust folder name of structural images
T1path = {{'/anatomy/anat.nii'}}; %if T1 is in analyze format reorient: pitch=-pi/2; roll=pi/2

%adjust name and path of pediatric template used
template = 'TPM.nii';
% templPath = ['/Users/danieljanko/Documents/MATLAB/spm12/tpm/' template];
templPath = '/Users/danieljanko/Documents/MATLAB/spm12/tpm/TPM.nii';
%template = 'TPM_Age7.nii'; %
%templPath = ['\\172.21.2.15\home\data\MiniMath\templates\' template];

%define subjects
subjectList = {'sub8', 'sub9', 'sub10', 'sub11', 'sub14', 'sub15','sub16', 'sub17', 'sub18', 'sub19', 'sub20', 'sub21', 'sub23', 'sub24', 'sub25', 'sub26', 'sub28'};


% scan parameters
nbslices    = 30;
TRsecs      = 1.8;%1.963;
TA          = 28;%(TRsecs/nbslices)*(nbslices-1)
%so          = [nbslices:-2:1, nbslices-1:-2:1]; %slice order for interleaved descending check here for alternatives https://github.com/rordenlab/spmScripts/blob/master/nii_batch12old.m
%slice_order = [1:2:nbslices 2:2:nbslices];
if mod(nbslices,2) %odd slice number
    so = [1:2:nbslices 2:2:nbslices];
    parameters.ref_slice = 1;
else
    so = [2:2:nbslices 1:2:nbslices];
    parameters.ref_slice = 2;
end
FWHMmm      = 7; %FWHM width of smoothing kernel

n_subj = numel(subjectList);

for subj = 1:n_subj
    for r = 1:2 %sessions
        disp(['Processing participant ' subjectList{subj} ' session ' r ]);
        clear matlabbatch;  % clear SPM batch.
        struct_dir = [studyPath subjectList{subj} T1path{1,1}{1}];

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%% REALIGN %%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %select all functional images 
        EPI = {};
        % Loop on sessions
        for j=1:numel(fMRIpaths{r,1})            
            fun_dir = [studyPath  subjectList{subj} fMRIpaths{r,1}{j}];
            f = spm_select('ExtFPList',  fun_dir, '^y-vol_.*\.nii$', 1);  
            matlabbatch{1}.spm.spatial.realign.estwrite.data = {cellstr(f)};
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 2;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [0 1];
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
            spm_jobman ('run', matlabbatch(1));
        end

        %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% SLICE TIMING %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%

        % select all resliced images
        % Loop on sessions

        for j=1:numel(fMRIpaths{r,1})            
            % Get EPI Realigned files without dummy files
            fun_dir = [studyPath  subjectList{subj} fMRIpaths{r,1}{j}];
            f = spm_select('ExtFPList',  fun_dir, '^y-vol_.*\.nii$', 1);
            matlabbatch{2}.spm.temporal.st.scans = {cellstr(f)}; 
            matlabbatch{2}.spm.temporal.st.nslices = nbslices;
            matlabbatch{2}.spm.temporal.st.tr = TRsecs;
            matlabbatch{2}.spm.temporal.st.ta = TA;
            matlabbatch{2}.spm.temporal.st.so = so; % for interleaved descending
            matlabbatch{2}.spm.temporal.st.refslice = so(nbslices/2); % middle slice
            matlabbatch{2}.spm.temporal.st.prefix = 'a';
            spm_jobman ('run', matlabbatch(2));
        end

        %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% COREGISTER %%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%% 

        %get mean functional image for coregistration 
        fun_dir = [studyPath  subjectList{subj} fMRIpaths{r,1}{j}];
        m = spm_select('ExtFPList',  fun_dir, '^meany.*.nii', 1); 
        matlabbatch{3}.spm.spatial.coreg.estimate.ref = {m};
        % get structural image for coregistration
        matlabbatch{3}.spm.spatial.coreg.estimate.source = {struct_dir};
        matlabbatch{3}.spm.spatial.coreg.estimate.other = {''};
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
        spm_jobman ('run', matlabbatch(3));

        %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% SEGMENTATION %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%% 

        %get coregistered structural images
        matlabbatch{4}.spm.spatial.preproc.channel.vols = {[struct_dir, ',1']};
        matlabbatch{4}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{4}.spm.spatial.preproc.channel.biasfwhm = 60;
        %Save Bias Corrected: Save Field and Corrected 
        matlabbatch{4}.spm.spatial.preproc.channel.write = [1 1];
        matlabbatch{4}.spm.spatial.preproc.tissue(1).tpm = {[templPath, ',1']};
        matlabbatch{4}.spm.spatial.preproc.tissue(1).ngaus = 2;
        matlabbatch{4}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(2).tpm = {[templPath, ',2']};
        matlabbatch{4}.spm.spatial.preproc.tissue(2).ngaus = 2;
        matlabbatch{4}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(3).tpm = {[templPath, ',3']};
        matlabbatch{4}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{4}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(4).tpm = {[templPath, ',4']};
        matlabbatch{4}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{4}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(5).tpm = {[templPath, ',5']};
        matlabbatch{4}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{4}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(6).tpm = {[templPath, ',6']};
        matlabbatch{4}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{4}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{4}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{4}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{4}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{4}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{4}.spm.spatial.preproc.warp.samp = 3;
        %Deformation Fields: Inverse + Forward
        matlabbatch{4}.spm.spatial.preproc.warp.write = [1 1];

        spm_jobman ('run', matlabbatch(4));

        %%%%%%%%%%%%%%%%%%%%%%%%
        %%%% DEFORMATIONS %%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%

        %define a path name to the structural file 
        struct = [studyPath subjectList{subj} '/anatomy'];
        matlabbatch{6}.spm.util.defs.comp{1}.def = cellstr(spm_select('FPList', struct, '^y_.*.nii'));
        %Specify  the  voxel  sizes  of the deformation field to be produced
        matlabbatch{6}.spm.util.defs.comp{2}.idbbvox.vox = [3 3 3];
        matlabbatch{6}.spm.util.defs.comp{2}.idbbvox.bb = [-90 -126 -72
                                                           91 91 109];
        matlabbatch{6}.spm.util.defs.out{1}.savedef.ofname = 'deformation';
        matlabbatch{6}.spm.util.defs.out{1}.savedef.savedir.saveusr = {struct};

        EPI = {};
        % Loop on sessions
        for j=1:numel(fMRIpaths{r,1})            
            % Get EPI Realigned files without dummy files
            fun_dir = [studyPath  subjectList{subj} task  fMRIpaths{r,1}{j}];
            f = spm_select('ExtFPList',  fun_dir, ['^ay-vol.*\.nii$'], Inf);  
            EPI = vertcat(EPI, cellstr(f));      
        end
        matlabbatch{6}.spm.util.defs.out{2}.pull.fnames = EPI;
        %matlabbatch{6}.spm.util.defs.out{2}.pull.fnames = cellstr(spm_select('FPList', fun_dir, '^au.*.nii'));
        matlabbatch{6}.spm.util.defs.out{2}.pull.savedir.savesrc = 1;
        matlabbatch{6}.spm.util.defs.out{2}.pull.interp = 7;
        matlabbatch{6}.spm.util.defs.out{2}.pull.mask = 1;
        matlabbatch{6}.spm.util.defs.out{2}.pull.fwhm = [7 7 7];

        spm_jobman ('run', matlabbatch(6));

        %%%%%%%%%%%%%%%%%%%%%%%%
        %%% Normalize %%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%

        % Get Field Deformation image
        forwardDeformation = spm_select('FPList', struct, '^y_deformation.nii$'); 

        % Get coregistered structural image 
        coregAnat = spm_select('FPList', struct, '^anat.nii$'); % not sure the correct image will be selected here since there should be two that correspond to this filter

        % Get Sliced EPI images of all runs
        EPI = {};
        % Loop on sessions
        for j=1:numel(fMRIpaths{r,1})            
            % Get EPI Realigned files without dummy files
            fun_dir = [studyPath  subjectList{subj} fMRIpaths{r,1}{j}];
            f = spm_select('ExtFPList',  fun_dir, ['^ay-vol.*\.nii$'], Inf); % make sure to have the proper name  
            EPI = vertcat(EPI, cellstr(f));      
        end

        % Get c1  c2  and c3 
        c1 = spm_select('FPList', struct, '^c1.*\.nii$'); 
        c2 = spm_select('FPList', struct,'^c2.*\.nii$');  
        c3 = spm_select('FPList', struct, '^c3.*\.nii$');  
        c1c2c3 = vertcat(c1, c2, c3);   

        clear matlabbatch;  % clear SPM batch. Otherwise we would re-run all of the hitherto run steps        
        matlabbatch{1}.spm.spatial.normalise.write.subj.def = {forwardDeformation};
        matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {coregAnat};
        matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = NaN(2,3);
        matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;

        matlabbatch{2}.spm.spatial.normalise.write.subj.def(1) = {forwardDeformation};
        matlabbatch{2}.spm.spatial.normalise.write.subj.resample = cellstr(EPI);    
        matlabbatch{2}.spm.spatial.normalise.write.woptions.bb = NaN(2,3);
        matlabbatch{2}.spm.spatial.normalise.write.woptions.vox = [3 3 3];
        matlabbatch{2}.spm.spatial.normalise.write.woptions.interp = 4;

        matlabbatch{3}.spm.spatial.normalise.write.subj.def(1) = {forwardDeformation};
        matlabbatch{3}.spm.spatial.normalise.write.subj.resample = cellstr(c1c2c3) ;   
        matlabbatch{3}.spm.spatial.normalise.write.woptions.bb = NaN(2,3);
        matlabbatch{3}.spm.spatial.normalise.write.woptions.vox = [3 3 3];
        matlabbatch{3}.spm.spatial.normalise.write.woptions.interp = 4;     

        spm_jobman('run',matlabbatch);  

        %%%%%%%%%%%%%%%%%%%%%%%%
        %%%% SMOOTH %%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%
        
        % Get Sliced EPI images of all runs
        EPI = {};
        % Loop on sessions
        for j=1:numel(fMRIpaths{r,1})            
            % Get EPI Realigned files without dummy files
            fun_dir = [studyPath  subjectList{subj} fMRIpaths{r,1}{j}];
            f = spm_select('ExtFPList',   fun_dir, '^way.*\.nii$');  % load normalized data.
            EPI = vertcat(EPI, cellstr(f));      
        end
        matlabbatch{6}.spm.spatial.smooth.data = EPI;
        %matlabbatch{10}.spm.spatial.smooth.data = spm_select('FPListRec', fun_dir, '^au.*\.nii$');
        matlabbatch{6}.spm.spatial.smooth.fwhm = [FWHMmm FWHMmm FWHMmm];
        matlabbatch{6}.spm.spatial.smooth.dtype = 0;
        matlabbatch{6}.spm.spatial.smooth.im = 0;
        matlabbatch{6}.spm.spatial.smooth.prefix = 's';

        spm_jobman('run',matlabbatch(6)); 
    end
end