#A script to match Area Deprivation Index and Child Opportunity Index data to participant child/adolescent addresses (lat/long) based on 2020 census block groups and tracts

library(dplyr)
library(sf)
library(tigris)
options(tigris_use_cache = TRUE)
library(tidygeocoder)
library(purrr)
library(ggplot2)
library(tidyr)
setwd("/Users/valeriesydnor/Documents/Image_Processing/hippocampal_myelin/")

########### Convert Participant Addresses to Latitudes and Longitudes ################

# Read in and format addresses
addresses.lncd <- read.csv("./sample_info/7T_MP2RAGE/7T_addresses.csv")
addresses.lncd <- addresses.lncd %>% filter(missing != 0) %>% filter(international != 0) #remove missing and international childhood addresses
addresses.lncd$full_address <- sprintf("%s, %s, %s %s", addresses.lncd$parent_guardian_address, addresses.lncd$pg_city, addresses.lncd$pg_state, addresses.lncd$pg_zip) #189 unique addresses from 301 visits

# Convert addresses to latitudes and longitudes using tidygeocoder 
addresses.lncd <- addresses.lncd %>% geocode(address = full_address, method  = "census", mode = "single", verbose = TRUE, full_results = TRUE)
write.csv(addresses.lncd, "./sample_info/7T_MP2RAGE/geocoded_addresses.csv", quote = T, row.names = F)

# Manually geocode n = 6 unique addresses (12 visits) that were not matched with tidygeocoder
# Read in final geocoded addresses after manual conversion
addresses.latlong <- read.csv("./sample_info/7T_MP2RAGE/geocoded_addresses_all.csv", fileEncoding = "Latin1")
addresses.latlong$lat <- as.numeric(addresses.latlong$lat)
addresses.latlong$long <- as.numeric(addresses.latlong$long)

########### Convert Latitudes and Longitudes to Spatial Point Geometries  ################

# Add geometry information and convert to simple features (sf)
### coordinate reference system (crs) defines whether spatial data is projected as geographic coordinates (degrees) or planar coordinates (distance)
### crs = 4269 is North American Datum, used by US census
addresses.latlong <- addresses.latlong %>% st_as_sf(coords = c("long", "lat"), remove = F, na.fail = T, crs = 4269) 

########### Access 2020 Census Block Group and Tract Data ################

states <- addresses.latlong$pg_state %>% trimws() %>% unique()

# Access 2020 census‐block group polygons with 12-digit GEOID and geometry for necessary states
censusblocks.allstates <- states %>% map_dfr(~ block_groups(state = .x, year = 2020, class = "sf"))

# Access 2020 census‐tract polygons with 11-digit GEOID and geometry for necessary states
censustracts.allstates <- states %>% map_dfr(~ tracts(state = .x, year = 2020, class = "sf"))

########### Merge Participant Geometries with Census Block Groups and Tracts ################

# Spatially locate each address's lat/long point geometries within the census block group or tract polygon
### point in polygon look-up
addresses.GEOIDs.blockgroup <- st_join(addresses.latlong, censusblocks.allstates["GEOID"], left = TRUE)
addresses.GEOIDs.blockgroup <- addresses.GEOIDs.blockgroup %>% select(lunaid, visitno, GEOID, tigerLine.tigerLineId, geometry) %>% rename(FIPS = GEOID)

addresses.GEOIDs.tracts <- st_join(addresses.latlong, censustracts.allstates["GEOID"], left = TRUE)
addresses.GEOIDs.tracts <- addresses.GEOIDs.tracts %>% select(lunaid, visitno, GEOID, tigerLine.tigerLineId, geometry) %>% rename(geoid20 = GEOID)

# Visualize location mapping
### PA
example.pa <- addresses.latlong[1, ]
bbox <- st_bbox(example.pa) + c(-3, -3, 3, 3)
tracts_near_point <- st_crop(censustracts.allstates, bbox)
ggplot() +
  geom_sf(data = tracts_near_point, fill = "white", color = "gray") +
  geom_sf(data = example.pa, color = "purple4", size = 3) +
  theme_minimal()

### NY
example.ny <- addresses.latlong[108, ]
bbox <- st_bbox(example.ny) + c(-3, -3, 3, 3)
tracts_near_point <- st_crop(censustracts.allstates, bbox)
ggplot() +
  geom_sf(data = tracts_near_point, fill = "white", color = "gray") +
  geom_sf(data = example.ny, color = "purple4", size = 3) +
  theme_minimal()

### MA
example.ma <- addresses.latlong[12, ]
bbox <- st_bbox(example.ma) + c(-3, -3, 3, 3)
tracts_near_point <- st_crop(censusblocks.allstates, bbox)
ggplot() +
  geom_sf(data = tracts_near_point, fill = "white", color = "gray") +
  geom_sf(data = example.ma, color = "purple4", size = 3) +
  theme_minimal()

########### Link Block Group GEOIDs (FIPS) to Area Deprivation Index Data ################

# Read in ADI data for 2020
### ADI data accessed from https://www.neighborhoodatlas.medicine.wisc.edu/download
environment.ADI <- read.csv("./environment/US_2020_ADI_Census_Block_Group_v4_0_1.csv")
environment.ADI$FIPS <- as.character(environment.ADI$FIPS)

# Get ADI scores for lncd participants
lncd.GEOID.ADI <- left_join(addresses.GEOIDs.blockgroup, environment.ADI, by = "FIPS")
lncd.GEOID.ADI <- sf::st_drop_geometry(lncd.GEOID.ADI) #remove geometry information 
lncd.GEOID.ADI <- lncd.GEOID.ADI %>% select(lunaid, visitno, FIPS, ADI_NATRANK)
colnames(lncd.GEOID.ADI) <- c("lunaid", "visitno", "FIPS", "ADI_natrank_youth")

########### Link Tract GEOIDs (geoid20) to Child Opportunity Index 3.0 Data ################

# Read in COI data and select scores for 2020
### COI data accessed from diversitydatakids.org: https://www.diversitydatakids.org/download-child-opportunity-index-data?_ga=2.119401353.1646392244.1753706768-1260614389.1752096099
environment.COI <- read.csv("./environment/COI3.0_overallscores.csv")
environment.COI <- environment.COI %>% filter(year == 2020) 
environment.COI$geoid20 <- as.character(environment.COI$geoid20)

# Get COI scores for lncd participants
lncd.GEOID.COI <- left_join(addresses.GEOIDs.tracts, environment.COI, by = "geoid20")
lncd.GEOID.COI <- sf::st_drop_geometry(lncd.GEOID.COI) #remove geometry information 
lncd.GEOID.COI <- lncd.GEOID.COI %>% select(lunaid, visitno, geoid20, contains("COI"), contains("HE_"), contains("SE_"), contains("ED_"))

########### Finalize and Save ################

lncd.GEOID.environment <- left_join(lncd.GEOID.ADI, lncd.GEOID.COI, by = c("lunaid", "visitno"))

merge7t <- read.csv("./sample_info/7T_MP2RAGE/merge_7t_04172025.csv") %>% select(lunaid, visitno, behave.date, top.mri.date)

lncd.GEOID.environment <- left_join(merge7t, lncd.GEOID.environment, by = c("lunaid", "visitno"))
lncd.GEOID.environment <- lncd.GEOID.environment %>% group_by(lunaid) %>% fill(6:43, .direction = "downup") %>% ungroup()

write.csv(lncd.GEOID.environment, "./sample_info/7T_MP2RAGE/geocoded_ADI_COI.csv", quote = F, row.names = F)
