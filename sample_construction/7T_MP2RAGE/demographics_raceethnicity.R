# A script to code participant race and ethnicity data 

library(tidyr)
library(dplyr)
library(stringr)
library(arrow)

# Final sample demos and R1  
hippocampal.R1 <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippocampal_R1_demographics.csv")

# Df with race and ethnicity information 
demo.load <- read.csv('/Volumes/Hera/Projects/Maria/demo_gdoc.csv') %>% select(ID, VisitYear, hispanic, american_indian, asian, black, hawaiian, white, unspecified)
colnames(demo.load)[1] <- "lunaid"
colnames(demo.load)[2] <- "visitno"

demo.load <- demo.load %>% distinct(lunaid, visitno, .keep_all = TRUE)

demo.load <- demo.load %>% 
             mutate_at(vars(american_indian), as.logical) %>%
             dplyr::mutate(hispanic = replace_na(hispanic, FALSE),
             american_indian = replace_na(american_indian, FALSE),
             asian = replace_na(asian, FALSE),
             black = replace_na(black, FALSE),
             hawaiian = replace_na(hawaiian, FALSE),
             white = replace_na(white, FALSE),
             unspecified = replace_na(unspecified, TRUE))

# Use self-identified participant race/ethnicity columns to create a single race_ethnicity col
race_cols <- names(demo.load)[4:9]

demo.load <- demo.load %>%
  mutate(
    n_true = rowSums(across(all_of(race_cols)), na.rm = TRUE),
    race_ethnicity = case_when(
      n_true > 1  ~ "multiracial",
      n_true == 1 ~ race_cols[max.col(across(all_of(race_cols)))],
      TRUE        ~ NA_character_
    )
  ) %>%
  select(-n_true)
demo.load$race_ethnicity[is.na(demo.load$race_ethnicity)] <- "unspecified"

# Numerical coding of race_ethnicity and hispanic ethnicity
demo.load$hispanic_coded <- as.integer(factor(demo.load$hispanic)) #1: not hispanic; 2: hispanic
demo.load$race_ethnicity <- factor(demo.load$race_ethnicity, levels = c("asian", "black", "white", "multiracial", "unspecified"))
demo.load$race_ethnicity_coded <- as.integer(demo.load$race_ethnicity) #1:asian, 2:black, 3:white, 4:multiracial, 5:unspecified

demo.load <- demo.load %>% filter(visitno == 1)
demo.load <- demo.load %>% select(lunaid, hispanic_coded, race_ethnicity_coded)
demo.load$lunaid <- as.integer(demo.load$lunaid)

# Merge race/ethnicity information into hippocampal_R1_demographics
hippocampal.R1 <- left_join(hippocampal.R1, demo.load, by = c("lunaid"))
hippocampal.R1$race_ethnicity_coded[is.na(hippocampal.R1$race_ethnicity_coded)] <- 5

table(hippocampal.R1$race_ethnicity_coded)
#asian: n=21
#black: n=35
#white: n=164
#multiracial: n=13
#unspecified: n=6

hippocampal.R1 <- hippocampal.R1 %>% select(subject_id, session_id, subses, lunaid, visitno, mp2rage.session_number, top.mri.date, behave.date, age, sex, hispanic_coded, race_ethnicity_coded, everything())

write.csv(hippocampal.R1, "/Volumes/Hera/Projects/hippocampal_myelin/output_measures/7T_MP2RAGE/hippocampal_R1_demographics.csv", quote = F, row.names = F)