#A script to match Child Opportunity Index data to participant addresses (lat/long) based on 2020 census tracts

library(dplyr)
library(sf)
library(tigris)
options(tigris_use_cache = TRUE)
library(tidygeocoder)
library(purrr)
library(ggplot2)
library(tidyr)

########### Convert Participant Addresses to Latitudes and Longitudes ################

# Read in and format addresses
addresses.lncd <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/sample_info/7T_MP2RAGE/7T_addresses.csv")
addresses.lncd <- addresses.lncd %>% filter(missing != 0) %>% filter(international != 0) #remove missing and international childhood addresses
addresses.lncd$full_address <- sprintf("%s, %s, %s %s", addresses.lncd$parent_guardian_address, addresses.lncd$pg_city, addresses.lncd$pg_state, addresses.lncd$pg_zip) #189 unique addresses from 301 visits

# Convert addresses to latitudes and longitudes using tidygeocoder 
addresses.lncd <- addresses.lncd %>% geocode(address = full_address, method  = "census", mode = "single", verbose = TRUE, full_results = TRUE)
write.csv(addresses.lncd, "/Volumes/Hera/Projects/hippocampal_myelin/sample_info/7T_MP2RAGE/geocoded_addresses.csv", quote = T, row.names = F)

# Manually geocode n = 6 unique addresses (12 visits) that were not matched with tidygeocoder
# Read in final geocoded addresses after manual conversion
addresses.latlong <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/sample_info/7T_MP2RAGE/geocoded_addresses_all.csv", fileEncoding = "Latin1")
addresses.latlong$lat <- as.numeric(addresses.latlong$lat)
addresses.latlong$long <- as.numeric(addresses.latlong$long)

########### Convert Latitudes and Longitudes to Spatial Point Geometries  ################

# Add geometry information and convert to simple features (sf)
### coordinate reference system (crs) defines whether spatial data is projected as geographic coordinates (degrees) or planar coordinates (distance)
### crs = 4269 is North American Datum, used by US census
addresses.latlong <- addresses.latlong %>% st_as_sf(coords = c("long", "lat"), remove = F, na.fail = T, crs = 4269) 

########### Access 2020 Census Tract Data ################

# Access 2020 census‐tract polygons with GEOID and geometry for necessary states
states <- addresses.latlong$pg_state %>% trimws() %>% unique()
censustracts.allstates <- states %>% map_dfr(~ tracts(state = .x, year = 2020, class = "sf"))

########### Merge Participant Geometries with Census Tracts ################

# Spatially locate each address's lat/long point geometries within the census tract polygon
### point in polygon look-up
addresses.GEOIDs <- st_join(addresses.latlong, censustracts.allstates["GEOID"], left = TRUE)
addresses.GEOIDs <- addresses.GEOIDs %>% select(lunaid, visitno, GEOID, tigerLine.tigerLineId, geometry) %>% rename(geoid20 = GEOID)

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
tracts_near_point <- st_crop(censustracts.allstates, bbox)
ggplot() +
  geom_sf(data = tracts_near_point, fill = "white", color = "gray") +
  geom_sf(data = example.ma, color = "purple4", size = 3) +
  theme_minimal()

########### Link GEOIDs to Child Opportunity Index 3.0 Data ################

# Read in COI Data and select scores for 2020
### COI data accessed from diversitydatakids.org: https://www.diversitydatakids.org/download-child-opportunity-index-data?_ga=2.119401353.1646392244.1753706768-1260614389.1752096099
environment.COI <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/child_opportunity_index/COI3.0_overallscores.csv")
environment.COI <- environment.COI %>% filter(year == 2020) 
environment.COI$geoid20 <- as.character(environment.COI$geoid20)

environment.COI.subdomains <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/child_opportunity_index/COI3.0_subdomains.csv")
environment.COI.subdomains <- environment.COI.subdomains %>% filter(year == 2020) 
environment.COI.subdomains$geoid20 <- as.character(environment.COI.subdomains$geoid20)

# Get COI Scores for lncd participants
lncd.GEOID.COI <- left_join(addresses.GEOIDs, environment.COI, by = "geoid20") #left join lncd GEOIDs to COI overall scores
lncd.GEOID.COI <- sf::st_drop_geometry(lncd.GEOID.COI) #remove geometry information 
write.csv(lncd.GEOID.COI, "/Volumes/Hera/Projects/hippocampal_myelin/child_opportunity_index/7T_MP2RAGE/7Tgeocoded_COI3.0_overallscores.csv", quote = T, row.names = F)

lncd.GEOID.COI.subdomains <- left_join(addresses.GEOIDs, environment.COI.subdomains, by = "geoid20")
lncd.GEOID.COI.subdomains <- sf::st_drop_geometry(lncd.GEOID.COI.subdomains) #remove geometry information 

lncd.GEOID.COI <- left_join(lncd.GEOID.COI, lncd.GEOID.COI.subdomains, by = c("lunaid", "visitno", "geoid20", "tigerLine.tigerLineId", "year", "state_fips", "state_usps",
                                                                              "state_name", "county_fips", "county_name", "metro_fips", "metro_name", "metro_type", "in100"))

########### Finalize LNCD Child Opportunity Index 3.0 Scores ################

merge7t <- read.csv("/Volumes/Hera/Projects/hippocampal_myelin/sample_info/7T_MP2RAGE/merge_7t_04172025.csv") %>% select(lunaid, visitno, behave.date, top.mri.date)
lncd.GEOID.COI <- left_join(merge7t, lncd.GEOID.COI, by = c("lunaid", "visitno"))
lncd.GEOID.COI <- lncd.GEOID.COI %>% group_by(lunaid) %>% fill(z_COI_nat, .direction = c("downup"))
lncd.GEOID.COI <- lncd.GEOID.COI %>% group_by(lunaid) %>% fill(17:178, .direction = "downup") %>% ungroup()

write.csv(lncd.GEOID.COI, "/Volumes/Hera/Projects/hippocampal_myelin/child_opportunity_index/7T_MP2RAGE/7Tgeocoded_COI3.0_overall_subdomains.csv", quote = T, row.names = F)
