#!/usr/bin/env bash

# A script to run hippunfold (https://hippunfold.khanlab.ca/en/latest/index.html) on MP2RAGE data
## docker run khanlab/hippunfold:latest --version : 1.5.2-pre.2

bids_dir="/Volumes/Hera/Projects/corticalmyelin_development/BIDS"
output_dir="/Volumes/Hera/Projects/hippunfold/output_1mm"

for sub_path in "$bids_dir"/sub-*/; do
    
    sub_id=$(basename "$sub_path")
    echo "checking $sub_id"

    coords_file=(${output_dir}/${sub_id}/ses-*/coords/sub-${sub_id}_ses-*_dir-AP_hemi-L_space-cropT1w_label-dentate_desc-laplace_coords.nii.gz)
    session=(${bids_dir}/${sub_id}/ses-*)
    num_ses=${#session[@]}  
    num_coords=${#coords_file[@]}  

    uni_t1s=($bids_dir/${sub_id}/ses-*/anat/${sub_id}_ses-*_acq-UNIDENT1corrected_T1w.nii.gz)
    num_uni=${#uni_t1s[@]}

    #check for UNICORT-corrected UNI T1w	    
    if [[ ! -f "${uni_t1s[0]}" ||  $num_uni -ne $num_ses ]]; then
       echo "ERROR: $sub_id number of uni's $num_uni not num ses $num_ses (uni: ${uni_t1s[*]}, bids: ${session[*]})"
       run_hipp=false
    fi
       
    #check if hippunfold should be run
    if [[ ! -f "${coords_file[0]}" ]]; then
        echo "Running hippunfold for $sub_id"
        run_hipp=true
    elif [[ $num_ses -eq $num_coords ]]; then
       echo "Hippunfold successfully ran for $sub_id ($num_ses sessions = $num_coords coordinate files)"
       run_hipp=false
    else
        echo "ERROR: For $sub_id, $num_ses sessions does not match $num_coords coordinate files; See $coords_file"
        run_hipp=false
    fi

    #run hippunfold via docker!
    if [[ "$run_hipp" == true ]]; then
        echo "  → Running HippUnfold for $sub_id..."
        tic=$(date +%s)
        dryrun time docker run \
            --user "$UID:$(id -g)" \
            --env HOME \
            -v /Volumes:/Volumes \
            -v "$PWD"/cache:/root/.cache/ \
            -v "$PWD"/cache:"$HOME/.cache/" \
            -it --rm \
            khanlab/hippunfold:latest \
            "$bids_dir" "$output_dir" participant \
            --participant-label "${sub_id/sub-/}" \
            --cores 15 \
            --path-T1w "$bids_dir/sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_acq-UNIDENT1corrected_T1w.nii.gz" \
            --modality T1w \ 
            --output_density 1mm \
            --rerun-incomplete

        echo "# end $(date +%s) - $tic start "
     fi
done
