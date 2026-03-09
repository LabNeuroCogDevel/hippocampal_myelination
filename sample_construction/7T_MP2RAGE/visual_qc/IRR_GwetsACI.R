# A script to calculate inter-rater reliability for visual QC of FreeSurfer hippocampal segmentations

library(dplyr)
library(irrCAC)
library(readODS)

# Visual QC ratings

fs.qc.SA.AM <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/sample_info/7T_MP2RAGE/7T_subcorticalR1_QC_SA_AM.csv")
fs.qc.VJS <- read_ods("/Volumes/Hera/Projects/hippocampal_myelin/sample_info/7T_MP2RAGE/7T_subcorticalR1_QC.ods") %>% select("subject_id", "session_id", "Freesurfer_completed", "R1_hippocampus_VJS")
fs.qc.SA.AM.VJS <- merge(fs.qc.SA.AM, fs.qc.VJS)
fs.qc.SA.AM.VJS <- fs.qc.SA.AM.VJS %>% filter(Freesurfer_completed == 1)

# Gwet's AC1 (first order agreement coefficient)
paste("SA and AM")
ratings <- fs.qc.SA.AM.VJS %>% select(R1_hippocampus_SA, R1_hippocampus_AM)
gwet.ac1.raw(ratings)

paste("SA and VJS")
ratings <- fs.qc.SA.AM.VJS %>% select(R1_hippocampus_SA, R1_hippocampus_VJS)
gwet.ac1.raw(ratings)

paste("AM and VJS")
ratings <- fs.qc.SA.AM.VJS %>% select(R1_hippocampus_AM, R1_hippocampus_VJS)
gwet.ac1.raw(ratings)

paste("SA, AM, and VJS")
ratings <- fs.qc.SA.AM.VJS %>% select(R1_hippocampus_SA, R1_hippocampus_AM, R1_hippocampus_VJS)
gwet.ac1.raw(ratings)