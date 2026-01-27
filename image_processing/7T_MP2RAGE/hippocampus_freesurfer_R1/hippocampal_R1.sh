#!/bin/bash

# A script to calculate average R1 in the left and right hippocampus for each participant, using freesurfer's aseg.mgz file generated during longitudinal recon-all

freesurfer_dir=/Volumes/Hera/Projects/hippocampal_myelin/freesurfer7.4.1_long
output_dir=/Volumes/Hera/Projects/hippocampal_myelin/output_measures

cd $freesurfer_dir

for subses in sub*long*; do
   echo $subses
   short="${subses%%.*}"
	singularity exec --containall --writable-tmpfs -B ${freesurfer_dir} -B /Volumes/Hera/Projects/hippocampal_myelin/software/license.txt:/opt/freesurfer/license.txt /Volumes/Hera/Projects/hippocampal_myelin/software/freesurfer-7.4.1.sif mri_segstats --seg ${freesurfer_dir}/$subses/mri/aseg.mgz --i ${freesurfer_dir}/$subses/mri/${short}_FScoreg_R1map.nii.gz --robust 2 --snr --id 17 53 --ctab /opt/freesurfer/FreeSurferColorLUT.txt --sum ${freesurfer_dir}/$subses/stats/hippocampus.aseg.R1.stats

done

#Combine participant-level stats files into one output for mean and std R1
singularity exec --containall --writable-tmpfs -B ${freesurfer_dir} -B ${freesurfer_dir}:/opt/freesurfer/subjects -B ${output_dir} -B /Volumes/Hera/Projects/hippocampal_myelin/software/license.txt:/opt/freesurfer/license.txt /Volumes/Hera/Projects/hippocampal_myelin/software/freesurfer-7.4.1.sif asegstats2table --subjects $(ls ${freesurfer_dir}) --statsfile hippocampus.aseg.R1.stats --meas mean --tablefile ${output_dir}/7T_MPRAGE/hippocampal_R1/hippocampus_meanR1_aseg_stats.txt --skip

singularity exec --containall --writable-tmpfs -B ${freesurfer_dir} -B ${freesurfer_dir}:/opt/freesurfer/subjects -B ${output_dir} -B /Volumes/Hera/Projects/hippocampal_myelin/software/license.txt:/opt/freesurfer/license.txt /Volumes/Hera/Projects/hippocampal_myelin/software/freesurfer-7.4.1.sif asegstats2table --subjects $(ls ${freesurfer_dir}) --statsfile hippocampus.aseg.R1.stats --meas std --tablefile ${output_dir}/7T_MP2RAGE/hippocampal_R1/hippocampus_stdR1_aseg_stats.txt --skip
