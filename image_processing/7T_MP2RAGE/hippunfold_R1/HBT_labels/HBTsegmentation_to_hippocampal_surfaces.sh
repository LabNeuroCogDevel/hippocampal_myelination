#!/bin/bash

# A script to project freesurfer hippocampal segmentations of head, body, tail to hippunfold surfaces 

project_dir=/Volumes/Hera/Projects/hippocampal_myelin
hippunfold_dir=/Volumes/Hera/Projects/hippunfold/output_1mm/hippunfold
freesurfer_dir=${project_dir}/freesurfer7.4.1_long
BIDS_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS
freesurfer_sif=${project_dir}/software/freesurfer-7.4.1.sif
freesurfer_license=${project_dir}/software/license.txt

for fs_dir in $freesurfer_dir/sub*ses*.long.sub*; do
	fs_id=$(basename ${fs_dir})
	subses=${fs_id%%.*}
	subject_id=${subses%_*}
	session_id=${subses#*_}
	UNI_dir=${BIDS_dir}/${subject_id}/${session_id}/anat
	fs_input=${fs_dir}/mri

#Register freesurfer hippocampal segmentations to processed UNI images using pre-computed lta files
	for hemi in lh rh; do
		singularity exec -B $freesurfer_dir:/opt/freesurfer/subjects -B $fs_input:/Freesurfer_input -B $UNI_dir:/UNI_dir -B $freesurfer_license:/opt/freesurfer/license.txt $freesurfer_sif mri_vol2vol --targ /Freesurfer_input/${hemi}.hippoAmygLabels-T1.long.v22.HBT.FSvoxelSpace.mgz --mov /UNI_dir/${subses}_acq-UNIDENT1corrected_T1w.nii.gz --lta /Freesurfer_input/${subses}_acq-UNIDENT1corrected_T1w_coreg_T1.lta --o /Freesurfer_input/${hemi}.hippoAmygLabels-T1.long.v22.HBT.UNIDENT1Space.nii.gz --interp nearest --inv
	done

#Combine left and right hemisphere segmentations	
	fslmaths ${fs_input}/lh.hippoAmygLabels-T1.long.v22.HBT.UNIDENT1Space.nii.gz -add ${fs_input}/rh.hippoAmygLabels-T1.long.v22.HBT.UNIDENT1Space.nii.gz ${fs_input}/hippoAmygLabels-T1.long.v22.HBT.UNIDENT1Space.nii.gz

#Project segmentation to hippunfold surfaces
	mkdir -p ${hippunfold_dir}/${subject_id}/${session_id}/HBT
	for hemi in L R; do
		for hpc in hipp dentate; do
			wb_command -volume-to-surface-mapping ${fs_input}/hippoAmygLabels-T1.long.v22.HBT.UNIDENT1Space.nii.gz ${hippunfold_dir}/${subject_id}/${session_id}/surf/${subses}_hemi-${hemi}_space-T1w_den-1mm_label-${hpc}_midthickness.surf.gii ${hippunfold_dir}/${subject_id}/${session_id}/HBT/${subses}_hemi-${hemi}_space-T1w_den-1mm_label-${hpc}_HBT.shape.gii -enclosing
			wb_command -metric-dilate ${hippunfold_dir}/${subject_id}/${session_id}/HBT/${subses}_hemi-${hemi}_space-T1w_den-1mm_label-${hpc}_HBT.shape.gii ${hippunfold_dir}/${subject_id}/${session_id}/surf/${subses}_hemi-${hemi}_space-T1w_den-1mm_label-${hpc}_midthickness.surf.gii 5 ${hippunfold_dir}/${subject_id}/${session_id}/HBT/${subses}_hemi-${hemi}_space-T1w_den-1mm_label-${hpc}_HBT.shape.gii -nearest 
		done
	done
done



