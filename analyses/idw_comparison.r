library(tidyverse)
library(rnoaa) # NOAA GHCND meteorological data queries

end_date <- "2021-06-02" # most recent date we want to analyze. Probably best to leave out at least the past few days, maybe more.

nwis_sites <- read_csv("download/site_list.csv")

# GHCND Site Selection----------------------------------------------------------

meteo_vars <- c("PRCP", "SNOW", "SNWD", "TMAX", "TMIN")

ghcnd_sites <- ghcnd_stations() %>%
  filter(element %in% meteo_vars,
         first_year < 2012,
         last_year > 2019,
         latitude > 35,
         latitude < 45,
         longitude > -95,
         longitude < -85)

nearby_sites <- list()

# https://www.r-bloggers.com/2010/11/great-circle-distance-calculations-in-r/
# Calculates the geodesic distance between two points specified by radian latitude/longitude using the
# Spherical Law of Cosines (slc)
gcd.slc <- function(long1, lat1, long2, lat2) {
  R <- 6371 # Earth mean radius [km]
  p <- pi/180
  d <- acos(sin(lat1*p)*sin(lat2*p) + cos(lat1*p)*cos(lat2*p) * cos(long2*p-long1*p)) * R
  return(d) # Distance in km
}

for (i in 1:nrow(nwis_sites)) {
  
  nearby_sites[[i]] <- ghcnd_sites %>%
    filter((latitude - nwis_sites$dec_lat_va[i])^2 + (longitude - nwis_sites$dec_long_va[i])^2 < 0.2) %>%
    mutate(approx_dist = gcd.slc(longitude, latitude, nwis_sites$dec_long_va[i], nwis_sites$dec_lat_va[i]),
           nwis_site = nwis_sites$site_no[i]) %>%
    arrange(approx_dist)
  
}

# GHCND Data Query--------------------------------------------------------------

nearby_sites <- bind_rows(nearby_sites)

ghcnd_ids <- nearby_sites %>%
  distinct(id) %>% .$id

ghcnd_data <- meteo_pull_monitors(ghcnd_ids, 
                                  date_min = "2010-01-01",
                                  date_max = end_date,
                                  var = meteo_vars)

