#A script to average R1 data in hippunfold surfaces across study participants

library(dplyr)
library(gifti)
library(ciftiTools)
ciftiTools.setOption('wb_path', '/Volumes/Hera/Projects/corticalmyelin_development/software/workbench')

participants <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippocampal_R1_demographics.csv")
hippunfold_surface_R1 <- readRDS("/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/hippunfold_surface_R1.rds")
hippunfold_surface_R1 <- lapply(hippunfold_surface_R1, function(surf){
	surf <- left_join(participants, surf, by = c("subject_id", "session_id"))
	return(surf)})

#Average vertex_wise R1 across participants
lh.hipp.R1 <- hippunfold_surface_R1$lh_hipp_R1 %>% select(contains("vertex")) %>% colMeans()
write_metric_gifti(x = lh.hipp.R1, gifti_fname = "/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/hippunfold_hemi-L_label-hipp_stat-meanR1.shape.gii", hemi = "left")

rh.hipp.R1 <- hippunfold_surface_R1$rh_hipp_R1 %>% select(contains("vertex")) %>% colMeans()
write_metric_gifti(x = rh.hipp.R1, gifti_fname = "/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/hippunfold_hemi-R_label-hipp_stat-meanR1.shape.gii", hemi = "right")

lh.dentate.R1 <- hippunfold_surface_R1$lh_dentate_R1 %>% select(contains("vertex")) %>% colMeans()
write_metric_gifti(x = lh.dentate.R1, gifti_fname = "/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/hippunfold_hemi-L_label-dentate_stat-meanR1.shape.gii", hemi = "left")

rh.dentate.R1 <- hippunfold_surface_R1$rh_dentate_R1 %>% select(contains("vertex")) %>% colMeans()
write_metric_gifti(x = rh.dentate.R1, gifti_fname = "/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/hippunfold_hemi-R_label-dentate_stat-meanR1.shape.gii", hemi = "right")
