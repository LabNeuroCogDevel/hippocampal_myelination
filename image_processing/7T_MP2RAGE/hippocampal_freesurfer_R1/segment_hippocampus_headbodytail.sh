#!/bin/bash

# A script to run longitudinal hippocampal segmentation to get head, body, tail

freesurfer_dir=/Volumes/Hera/Projects/hippocampal_myelin/freesurfer7.4.1_long
export FREESURFER_HOME=/opt/ni_tools/freesurfer7.4.1
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export SUBJECTS_DIR=$freesurfer_dir

for fsdir in ${freesurfer_dir}/*long*; do
	dirname=${fsdir##*/}
	if ! [[ -f $fsdir/mri/lh.hippoAmygLabels-T1.long.v22.HBT.mgz ]]; then
	       base=${fsdir##*.}
	       echo "running hippocampal segmentation for $base"
	       segmentHA_T1_long.sh $base $freesurfer_dir &
	fi
	waitforjobs -j 30 --sleeptime 120s
done
