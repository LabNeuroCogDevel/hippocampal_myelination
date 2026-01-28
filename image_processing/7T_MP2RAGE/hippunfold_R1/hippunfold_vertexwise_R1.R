# A script to extract and collate vertex-wise R1 data from hemisphere-specific hippocampal surface giftis into study-specific dfs

library(dplyr)
library(gifti)
library(stringr)

project_dir="/Volumes/Hera/Projects/hippocampal_myelin"
hippunfold_dir="/Volumes/Hera/Projects/hippunfold/output_1mm/hippunfold"

extract_R1 <- function(file){
	subject_id <- str_extract(file, "sub-[^/]+")
	session_id <- str_extract(file, "ses-[^/]+")
	R1_gifti <- readgii(file)
	R1_data <- t(R1_gifti$data$normal)
	colnames(R1_data) <- paste0("vertex_", seq_along(R1_data))
	R1_data <- data.frame(subject_id = subject_id, session_id = session_id, R1_data) 
	return(R1_data)
}

########### Main hippocampal surface (label-hipp) ################

lh_hippsurface_files <- list.files(path = hippunfold_dir, pattern = "hemi-L_space-T1w_den-1mm_label-hipp_R1\\.shape\\.gii$", recursive = T, full.names = T)
rh_hippsurface_files <- list.files(path = hippunfold_dir, pattern = "hemi-R_space-T1w_den-1mm_label-hipp_R1\\.shape\\.gii$", recursive = T, full.names = T)

lh_hippsurface_R1 <- bind_rows(lapply(lh_hippsurface_files, function(f) {extract_R1(f)}))
rh_hippsurface_R1 <- bind_rows(lapply(rh_hippsurface_files, function(f) {extract_R1(f)}))

########### Dentate gyrus surface (label-dentate) ################

lh_dentatesurface_files <- list.files(path = hippunfold_dir, pattern = "hemi-L_space-T1w_den-1mm_label-dentate_R1\\.shape\\.gii$", recursive = T, full.names = T)
rh_dentatesurface_files <- list.files(path = hippunfold_dir, pattern = "hemi-R_space-T1w_den-1mm_label-dentate_R1\\.shape\\.gii$", recursive = T, full.names = T)

lh_dentatesurface_R1 <- bind_rows(lapply(lh_dentatesurface_files, function(f) {extract_R1(f)}))
rh_dentatesurface_R1 <- bind_rows(lapply(rh_dentatesurface_files, function(f) {extract_R1(f)}))

########### Combine and save ################

hippunfold_surface_R1 <- list(lh_hippsurface_R1, rh_hippsurface_R1, lh_dentatesurface_R1, rh_dentatesurface_R1)
names(hippunfold_surface_R1) <- c("lh_hipp_R1", "rh_hipp_R1", "lh_dentate_R1", "rh_dentate_R1")
saveRDS(hippunfold_surface_R1, "/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippunfold_R1/hippunfold_surface_R1.rds")
