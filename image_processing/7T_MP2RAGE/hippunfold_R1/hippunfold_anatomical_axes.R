# A script to extract A-P and L-R axis locations for hippunfold surfaces

library(dplyr)
library(gifti)
library(ciftiTools)
ciftiTools.setOption('wb_path', '/Volumes/Hera/Projects/corticalmyelin_development/software/workbench')

project_dir="/Volumes/Hera/Projects/hippocampal_myelin"
hippunfold_dir="/Volumes/Hera/Projects/hippunfold/output_1mm/hippunfold"

extract_coords <- function(hemi, hemi.name, surf){
	surface_file <- sprintf("%s/sub-10129/ses-20180917/surf/sub-10129_ses-20180917_hemi-%s_space-unfold_den-1mm_label-%s_midthickness.surf.gii", hippunfold_dir, hemi.name, surf)
	surface_gifti <- readgii(surface_file)
	AP.coords <- scale(surface_gifti$data$pointset[,1]) %>% as.vector() #A-P coordinates z-score
	LR.coords <- scale(surface_gifti$data$pointset[,2]) %>% as.vector() #L-R coordinates z-score
	write_metric_gifti(x = AP.coords, gifti_fname = sprintf("%s/output_measures/7T_MP2RAGE/hippunfold_R1/hippunfold_hemi-%s_label-%s_stat-APaxis.shape.gii", project_dir, hemi.name, surf), hemisphere = hemi, col_names = c("axis"))
	write_metric_gifti(x = LR.coords, gifti_fname = sprintf("%s/output_measures/7T_MP2RAGE/hippunfold_R1/hippunfold_hemi-%s_label-%s_stat-LRaxis.shape.gii", project_dir, hemi.name, surf), hemisphere = hemi, col_names = c("axis"))
}

########### Main hippocampal surface (label-hipp) ###########

extract_coords(hemi = "left", hemi.name = "L", surf = "hipp")
extract_coords(hemi = "right", hemi.name = "R", surf = "hipp")

########### Dentate gyrus surface (label-dentate) ###########

extract_coords(hemi = "left", hemi.name = "L", surf = "dentate")
extract_coords(hemi = "right", hemi.name = "R", surf = "dentate")
