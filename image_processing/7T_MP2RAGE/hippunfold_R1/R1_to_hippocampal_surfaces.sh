#!/bin/bash

# A script to project volumetric R1 data from the hippocampus to hippunfold surfaces

project_dir=/Volumes/Hera/Projects/hippocampal_myelin
hippunfold_dir=/Volumes/Hera/Projects/hippunfold/output_1mm/hippunfold
R1map_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/R1maps

for R1map in ${R1map_dir}/sub*/ses*/*R1map.nii.gz; do
	
	subses=$(echo $R1map | grep -o 'sub-[^/]*_ses-[^_]*')
	subject_id="${subses%%_*}"
	session_id="${subses#*_}"
	
	R1_projections=(${hippunfold_dir}/${subject_id}/${session_id}/R1/${subses}_hemi-*_space-T1w_den-1mm_label-*_R1.shape.gii)
	N_projections=${#R1_projections[@]}

	if [[ $N_projections -eq 4 ]]; then
		echo "R1 data already mapped to all 4 hippunfold surfaces for $subses"
		continue
	fi
	
	if [[ ! -d "${hippunfold_dir}/${subject_id}/${session_id}/surf" ]]; then
		echo "hippunfold outputs missing for $subses"
		continue
	fi
		
	echo "Projecting R1 data to hippunfold surfaces for $subses"
	mkdir -p ${hippunfold_dir}/${subject_id}/${session_id}/R1
	for hemi in L R; do
		for hpc in hipp dentate; do
			wb_command -volume-to-surface-mapping ${R1map_dir}/${subject_id}/${session_id}/${subses}_R1map.nii.gz ${hippunfold_dir}/${subject_id}/${session_id}/surf/${subses}_hemi-${hemi}_space-T1w_den-1mm_label-${hpc}_midthickness.surf.gii ${hippunfold_dir}/${subject_id}/${session_id}/R1/${subses}_hemi-${hemi}_space-T1w_den-1mm_label-${hpc}_R1.shape.gii -trilinear 
		done
	done
done

