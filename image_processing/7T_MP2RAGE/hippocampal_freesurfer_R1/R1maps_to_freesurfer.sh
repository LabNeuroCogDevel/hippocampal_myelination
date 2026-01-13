#!/bin/bash

#A script to register R1 maps to subject longitudinal Freesurfer anatomical space using pre-computed lta files

project_dir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
freesurfer_dir=${project_dir}/BIDS/derivatives/freesurfer7.4.1_long
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
freesurfer_license=${project_dir}/software/license.txt
R1_dir=${project_dir}/BIDS/derivatives/R1maps

for fs_dir in $freesurfer_dir/sub*ses*.long.sub*; do
	fs_id=$(basename ${fs_dir})
	subses=${fs_id%%.*}
	subject_id=${subses%_*}
	session_id=${subses#*_}

	fs_input=${fs_dir}/mri
	R1_input=${R1_dir}/${subject_id}/${session_id}	

	singularity exec -B $freesurfer_dir:/opt/freesurfer/subjects -B $fs_input:/Freesurfer_input -B $R1_input:/R1_input -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2vol --mov /R1_input/${subject_id}_${session_id}_R1map.nii.gz --targ /Freesurfer_input/T1.mgz --lta /Freesurfer_input/${subject_id}_${session_id}_acq-UNIDENT1corrected_T1w_coreg_T1.lta --o /Freesurfer_input/${subject_id}_${session_id}_FScoreg_R1map.nii.gz 

done

