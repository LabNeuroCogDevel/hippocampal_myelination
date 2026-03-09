#!/bin/bash

# A script to get hippunfold dice values for left and right hippocampus

project_dir=/Volumes/Hera/Projects/hippocampal_myelin
hippunfold_dir=/Volumes/Hera/Projects/hippunfold/output_1mm/hippunfold

echo "subject_id,session_id,hemi,dice" >> ${project_dir}/output_measures/7T_MP2RAGE/hippunfold_R1/quality_control/hippocampus_dice.csv

for dice_file in ${hippunfold_dir}/sub-*/ses-*/qc/*_hemi-*_desc-unetf3d_dice.tsv ; do

    base=$(basename "$dice_file")

    if [[ $base =~ (sub-[^_]+)_(ses-[^_]+)_hemi-([LR]) ]]; then
        subject_id="${BASH_REMATCH[1]}"
        session_id="${BASH_REMATCH[2]}"
        hemi="${BASH_REMATCH[3]}"
    fi

    dice=$(cat $dice_file)

    echo "$subject_id,$session_id,$hemi,$dice" >> ${project_dir}/output_measures/7T_MP2RAGE/hippunfold_R1/quality_control/hippocampus_dice.csv

done
