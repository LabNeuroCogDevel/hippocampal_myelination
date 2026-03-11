# A script to organize and score WHOQOL-BREF data

library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)
library(purrr)

###########################################################################################################
#### Read in survey data ####

load("/Volumes/Hera/Projects/7TBrainMech/scripts/behave/all_reports_list.RData") #list of self-report data from 418 visits

###########################################################################################################
#### Extract participant/visit IDs and WHOQOL-BREF questions from surveys ####

readwhoqol <- function(d) {
  
  #Format visit-specific survery df 
  if(ncol(d) < 20) return(NULL) 
  colnames(d) <- d[1,]
  d <- d[nrow(d), ]
  
  #Extract participant and visit information
  lunaid <- as.integer(sub(".*/(\\d+)_.*", "\\1", d[1,1]))
  behave.date <- as.Date(sub(".*_(\\d{8}).*", "\\1", d[1,1]), "%Y%m%d")
  survey.date <- d %>% select(contains("Today's date")) %>% pull() %>% as.Date(format = "%m/%d/%Y")
  birth.date <- d %>% select(contains("Your birthday")) %>% pull() %>% as.Date(format = "%m/%d/%Y")
  sex <- d %>% select(contains("Your gender")) %>% pull() 
  id.info <- data.frame("lunaid" = lunaid, "behave.date" = behave.date, "survey.date" = survey.date, "birth.date" = birth.date, "sex" = sex)
  
  #Identify whoqol questions
  i <- names(d) |> grep(pattern = "How would you rate your quality of life?") #identify position of first question in the whoqol battery
  names(d)[i: (i+25)] <- paste('whoqol', 1:26, sep = '') #identify and rename all whoqol questions
  whoqol.data <- d %>% select(contains("whoqol", ignore.case = FALSE))
  whoqol.data <- cbind(id.info, whoqol.data)

  return(whoqol.data)
}

whoqol.all <- map_dfr(all_reports_list, readwhoqol)

###########################################################################################################
#### Convert WHOQOL-BREF string responses to numeric ####

convertwhoqol <- function(x) {
  case_when(
    tolower(x) %in% c("very poor", "very dissatisfied", "not at all", "never", 1) ~ 1,
    tolower(x) %in% c("poor", "dissatisfied", "a little", "seldom", "2") ~ 2,
    tolower(x) %in% c("moderately", "neither poor nor good", "neither dissatisfied nor satisfied", "neither satisfied nor dissatisfied", "a moderate amount", "quite often", "neither poor nor well", "3") ~ 3,
    tolower(x) %in% c("good", "satisfied", "very much", "mostly", "well", "very often", "4") ~ 4,
    tolower(x) %in% c("completely", "very good", "very well", "very satisfied", "an extreme amount", "extremely", "completely", "always", "5") ~ 5)
}

whoqol.numeric <- whoqol.all %>% mutate(across(contains("whoqol"), convertwhoqol))
whoqol.cols <- grep("whoqol", names(whoqol.numeric), value = TRUE)
whoqol.numeric <- whoqol.numeric[rowSums(is.na(whoqol.numeric[whoqol.cols])) < 6, ] # remove visits with > 5 missing questions

###########################################################################################################
#### Score the WHOQOL-BREF ####

#### Overall quality of life: 1
#### Overall health satisfaction: 2
#### Physical health: 3, 4, 10, 15, 16, 17, 18
#### Psychological: 5, 6, 7, 11, 19, 26
#### Social: 20, 21, 22
#### Environment: 8, 9, 12, 13, 14, 23, 24, 25

# Reverse score items 
whoqol.numeric$whoqol3 <- 6-whoqol.numeric$whoqol3
whoqol.numeric$whoqol4 <- 6-whoqol.numeric$whoqol4
whoqol.numeric$whoqol26 <- 6-whoqol.numeric$whoqol26

# Compute domain scores
scorewhoqol <- function(items) {
  domain.data <- whoqol.numeric[items]
  
  #Impute NAs with average of other items in domain
  domain.data <- domain.data %>% rowwise() %>%
    mutate(across(1:ncol(domain.data), ~ ifelse(is.na(.), round(mean(c_across(1:ncol(domain.data)), na.rm = TRUE)), .))) %>%
    ungroup()
  
  #Obtain domain mean
  domain.score <- rowMeans(domain.data)
  
  #Multiply domain score by 4
  domain.score <- domain.score*4
  
  #Transform to 0-100 scale
  domain.score <- (domain.score - 4)*(100/16)
  
  return(domain.score)
}

whoqol.scored <- whoqol.numeric %>% mutate(whoqol_overall_qol = whoqol1,
                                           whoqol_overall_health = whoqol2,
                                           whoqol_physical = scorewhoqol(items = c("whoqol3", "whoqol4", "whoqol10", "whoqol15", "whoqol16", "whoqol17", "whoqol18")),
                                           whoqol_psychological = scorewhoqol(items = c("whoqol5", "whoqol6", "whoqol7", "whoqol11", "whoqol19", "whoqol26")),
                                           whoqol_social = scorewhoqol(items = c("whoqol20", "whoqol21", "whoqol22")),
                                           whoqol_environment = scorewhoqol(items = c("whoqol8", "whoqol9", "whoqol12", "whoqol13", "whoqol14","whoqol23", "whoqol24", "whoqol25")))
whoqol.scored <- whoqol.scored %>% select(lunaid, behave.date, whoqol_overall_qol, whoqol_overall_health, whoqol_physical, whoqol_psychological, whoqol_social, whoqol_environment, whoqol8, whoqol9, whoqol12, whoqol13, whoqol14, whoqol23, whoqol24, whoqol25)
names(whoqol.scored) <- c("lunaid", "behave.date", "whoqol_overall_qol", "whoqol_overall_health", "whoqol_physical", "whoqol_psychological", "whoqol_social", "whoqol_environment", "whoqol_env_safety", "whoqol_env_physicalenv", "whoqol_env_financial", "whoqol_env_information", "whoqol_env_leisure", "whoqol_env_livingplace", "whoqol_env_healthservices", "whoqol_env_transport")
whoqol.scored <- whoqol.scored %>% distinct(lunaid, behave.date, .keep_all = TRUE) # remove a few repeat survey entries

write.csv(whoqol.scored, "/Volumes/Hera/Projects/hippocampal_myelin/sample_info/7T_MP2RAGE/whoqol-bref.csv", quote = F, row.names = F)
