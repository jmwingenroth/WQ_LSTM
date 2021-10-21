library(tidyverse)
library(rnoaa) # NOAA GHCND meteorological data queries
library(baytrends) # interpolation

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

# GHCND Spatial Averaging-------------------------------------------------------

idw_power <- seq(0, 30, by = .5)

ghcnd_tidy <- list()

big_ghcnd <- left_join(ghcnd_data, nearby_sites, by = "id") %>%
  distinct(id, date, prcp, snow, snwd, tmax, tmin, latitude, longitude, approx_dist, nwis_site)

for (i in 1:length(idw_power)) {
  
  ghcnd_tidy[[i]] <- big_ghcnd %>%
    group_by(nwis_site, date) %>%
    arrange(nwis_site, date) %>%
    mutate(rel_weight = approx_dist^-idw_power[i]) %>%
    summarise(prcp = weighted.mean(prcp, rel_weight, na.rm = TRUE),
              snow = weighted.mean(snow, rel_weight, na.rm = TRUE),
              snwd = weighted.mean(snwd, rel_weight, na.rm = TRUE),
              tmin = weighted.mean(tmin, rel_weight, na.rm = TRUE),
              tmax = weighted.mean(tmax, rel_weight, na.rm = TRUE)) %>%
    mutate(idw_power = idw_power[i])
  
}
  
# GHCND Gap Filling-------------------------------------------------------------

for (i in 1:length(idw_power)) { # length(ghcnd_tidy)==length(idw_power)
  
  ghcnd_tidy[[i]] <- ghcnd_tidy[[i]] %>%
    mutate(across(c(prcp,snow), function(x) if_else(is.na(x),
                                                    0,
                                                    x))) %>%
    mutate(across(c(snwd,tmax,tmin), ~fillMissing(.x, span = 1, max.fill = 21)))
  
  if (sum(is.na(ghcnd_tidy[[i]])) == 0) cat("Data filled successfully for idw_power =",idw_power[i],"\n")
  
}

# IDW Comparison----------------------------------------------------------------

ghcnd_tidy2 <- bind_rows(ghcnd_tidy)

ghcnd_tidy2 %>%
  filter(nwis_site == "03346500") %>%
  ggplot(aes(x = date, y = prcp, color = idw_power)) +
  geom_line(alpha = .1) +
  scale_color_viridis_c() +
  scale_x_date(limits = as.Date(c("2015-06-01",
                                  "2015-09-01"))) +
  ggtitle(label = "Site 03346500: July 2015 Precipitation")
