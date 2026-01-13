#!/bin/bash

# A script to calculate average R1 in the head, body,and tail of the left and right hippocampi for each participant, using freesurfer's $h.hippoAmygLabels-T1.long.v22.HBN.mgz files generated during longitudinal hippocampal segmentation. Also calculates HBT volume

freesurfer_dir=/Volumes/Hera/Projects/hippocampal_myelin/freesurfer7.4.1_long
output_dir=/Volumes/Hera/Projects/hippocampal_myelin/output_measures

cd $freesurfer_dir

#Compute timepoint-specific head, body, tail R1
for subses in sub*long*; do
   echo $subses
   short="${subses%%.*}"
   
   for hemi in lh rh; do
	   singularity exec --containall --writable-tmpfs -B ${freesurfer_dir} -B /Volumes/Hera/Projects/hippocampal_myelin/software/license.txt:/opt/freesurfer/license.txt /Volumes/Hera/Projects/hippocampal_myelin/software/freesurfer-7.4.1.sif mri_segstats --seg ${freesurfer_dir}/$subses/mri/${hemi}.hippoAmygLabels-T1.long.v22.HBT.FSvoxelSpace.mgz --i ${freesurfer_dir}/$subses/mri/${short}_FScoreg_R1map.nii.gz --robust 2 --snr --id 226 231 232 --ctab /opt/freesurfer/FreeSurferColorLUT.txt --sum ${freesurfer_dir}/$subses/stats/${hemi}.hippocampus.HBT.R1.stats
   done
done

#Combine participant-level R1 stats into hemisphere-specific output for full study sample
for hemi in lh rh; do
	singularity exec --containall --writable-tmpfs  -B ${freesurfer_dir} -B ${freesurfer_dir}:/opt/freesurfer/subjects -B ${output_dir} -B /Volumes/Hera/Projects/hippocampal_myelin/software/license.txt:/opt/freesurfer/license.txt /Volumes/Hera/Projects/hippocampal_myelin/software/freesurfer-7.4.1.sif asegstats2table --subjects $(ls ${freesurfer_dir}) --statsfile ${hemi}.hippocampus.HBT.R1.stats --meas mean --tablefile ${output_dir}/7T_MP2RAGE/hippocampal_R1/${hemi}.hippocampus_meanR1_HBT_stats.txt --skip
done

#Combine participant-level volumetric stats into hemisphere-specific output for full study sample
for hemi in lh rh; do
	singularity exec --containall --writable-tmpfs  -B ${freesurfer_dir} -B ${freesurfer_dir}:/opt/freesurfer/subjects -B ${output_dir} -B /Volumes/Hera/Projects/hippocampal_myelin/software/license.txt:/opt/freesurfer/license.txt /Volumes/Hera/Projects/hippocampal_myelin/software/freesurfer-7.4.1.sif asegstats2table --subjects $(ls ${freesurfer_dir}) --statsfile ${hemi}.hippocampus.HBT.R1.stats --meas volume --tablefile ${output_dir}/7T_MP2RAGE/hippocampal_volume/${hemi}.hippocampus_volume_HBT_stats.txt --skip
done
