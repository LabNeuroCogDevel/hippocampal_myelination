# A script to create study-specific hippocampal segmentations in hippunfold surface space 

library(dplyr)
library(gifti)
library(stringr)
library(ciftiTools)
ciftiTools.setOption('wb_path', '/Volumes/Hera/Projects/corticalmyelin_development/software/workbench')

project_dir="/Volumes/Hera/Projects/hippocampal_myelin"
hippunfold_dir="/Volumes/Hera/Projects/hippunfold/output_1mm/hippunfold"

participants <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippocampal_R1_demographics.csv") %>% select(subject_id, session_id)

extract_HBT <- function(file){
	subject_id <- str_extract(file, "sub-[^/]+")
	session_id <- str_extract(file, "ses-[^/]+")
	HBT_gifti <- readgii(file)
	HBT_data <- t(HBT_gifti$data$normal)
	colnames(HBT_data) <- paste0("vertex_", seq_along(HBT_data))
	HBT_data <- data.frame(subject_id = subject_id, session_id = session_id, HBT_data) 
	return(HBT_data)
}

########### Main hippocampal surface (label-hipp) ################

lh_hippsurface_files <- list.files(path = hippunfold_dir, pattern = "hemi-L_space-T1w_den-1mm_label-hipp_HBT\\.shape\\.gii$", recursive = T, full.names = T)
rh_hippsurface_files <- list.files(path = hippunfold_dir, pattern = "hemi-R_space-T1w_den-1mm_label-hipp_HBT\\.shape\\.gii$", recursive = T, full.names = T)

lh_hippsurface_HBT <- bind_rows(lapply(lh_hippsurface_files, function(f) {extract_HBT(f)}))
lh_hippsurface_HBT <- left_join(participants, lh_hippsurface_HBT)
lh_hippsurface_HBT <- lh_hippsurface_HBT %>% select(-subject_id, -session_id)
lh_hippsurface_HBT.mask <- lh_hippsurface_HBT %>% summarise(across(everything(), ~ as.numeric(names(which.max(table(.)))))) %>% t() %>% as.data.frame()
write_metric_gifti(x = lh_hippsurface_HBT.mask$V1, hemisphere = "left", gifti_fname="/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/HBT_segmentation/hippunfold_hemi_L_label-hipp_atlas-HBT.shape.gii")

rh_hippsurface_HBT <- bind_rows(lapply(rh_hippsurface_files, function(f) {extract_HBT(f)}))
rh_hippsurface_HBT <- left_join(participants, rh_hippsurface_HBT)
rh_hippsurface_HBT <- rh_hippsurface_HBT %>% select(-subject_id, -session_id)
rh_hippsurface_HBT.mask <- rh_hippsurface_HBT %>% summarise(across(everything(), ~ as.numeric(names(which.max(table(.)))))) %>% t() %>% as.data.frame()
write_metric_gifti(x = rh_hippsurface_HBT.mask$V1, hemisphere = "right", gifti_fname="/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/HBT_segmentation/hippunfold_hemi_R_label-hipp_atlas-HBT.shape.gii")

########### Dentate gyrus surface (label-dentate) ################

lh_dentatesurface_files <- list.files(path = hippunfold_dir, pattern = "hemi-L_space-T1w_den-1mm_label-dentate_HBT\\.shape\\.gii$", recursive = T, full.names = T)
rh_dentatesurface_files <- list.files(path = hippunfold_dir, pattern = "hemi-R_space-T1w_den-1mm_label-dentate_HBT\\.shape\\.gii$", recursive = T, full.names = T)

lh_dentatesurface_HBT <- bind_rows(lapply(lh_dentatesurface_files, function(f) {extract_HBT(f)}))
lh_dentatesurface_HBT <- left_join(participants, lh_dentatesurface_HBT)
lh_dentatesurface_HBT <- lh_dentatesurface_HBT %>% select(-subject_id, -session_id)
lh_dentatesurface_HBT.mask <- lh_dentatesurface_HBT %>% summarise(across(everything(), ~ as.numeric(names(which.max(table(.)))))) %>% t() %>% as.data.frame()
write_metric_gifti(x = lh_dentatesurface_HBT.mask$V1, hemisphere = "left", gifti_fname="/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/HBT_segmentation/hippunfold_hemi_L_label-dentate_atlas-HBT.shape.gii")

rh_dentatesurface_HBT <- bind_rows(lapply(rh_dentatesurface_files, function(f) {extract_HBT(f)}))
rh_dentatesurface_HBT <- left_join(participants, rh_dentatesurface_HBT)
rh_dentatesurface_HBT <- rh_dentatesurface_HBT %>% select(-subject_id, -session_id)
rh_dentatesurface_HBT.mask <- rh_dentatesurface_HBT %>% summarise(across(everything(), ~ as.numeric(names(which.max(table(.)))))) %>% t() %>% as.data.frame()
write_metric_gifti(x = rh_dentatesurface_HBT.mask$V1, hemisphere = "right", gifti_fname="/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/HBT_segmentation/hippunfold_hemi_R_label-dentate_atlas-HBT.shape.gii")

