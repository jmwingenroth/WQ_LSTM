library(tidyverse)
library(rnoaa) #NOAA GHCND meteorological data queries
library(dataRetrieval) # USGS NWIS hydrologic data queries

# NWIS Site Selection-----------------------------------------------------------

US_states <- c('AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
               'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
               'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
               'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
               'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY')

nitrate_sites <- list()

for (i in 1:50) {
  try(nitrate_sites[[i]] <- whatNWISdata(stateCd = US_states[i], 
                                         service = "dv", 
                                         statCd = "00003", 
                                         parameterCd = "99133"))    
}

nitrate_sites <- nitrate_sites[lengths(nitrate_sites) > 0]

nitrate_sites <- nitrate_sites[lapply(nitrate_sites, nrow) > 0]

nitrate_sites <- lapply(nitrate_sites, function(x) select(x, -alt_acy_va)) %>%
  bind_rows()

nitr_delin <- read_csv("data query/delineated_sites.csv") %>% #file contains ~19,000 delineated watersheds
  right_join(nitrate_sites, by = c("SITE_NO" = "site_no")) %>%
  filter(!is.na(SQMI))

data_avail <- whatNWISdata(siteNumbers = nitr_delin$SITE_NO, 
                           statCd = c("00003","00008"), # 00003 is mean, 00008 is median (median needed for pH) 
                           service = "dv") 

parm_key <- readNWISpCode(unique(data_avail$parm_cd)) %>%
  arrange(parameter_cd)

candidates_lengths <- left_join(data_avail, parm_key, by = c("parm_cd" = "parameter_cd")) %>%
  group_by(station_nm, parm_cd, site_no) %>%
  summarize(count_nu = sum(count_nu)) %>%
  pivot_wider(names_from = parm_cd, values_from = count_nu) %>%
  filter(`00060` > 1000,
         `99133` > 500, 
         `00010` > 500, 
         `00095` > 500, 
         `00300` > 500, 
         `00400` > 500, 
         `63680` > 500, 
         as.numeric(site_no) > 3e6,
         site_no != "05599490") %>%
  arrange(site_no) %>%
  select(station_nm, site_no, `00060`, `00010`, `99133`, everything())

# NWIS Data Query--------------------------------------------------------------

candidates_meta <- whatNWISsites(siteNumbers = candidates_lengths$site_no)

nwis_data <- readNWISdv(siteNumbers = candidates_meta$site_no, 
           parameterCd = c('00060',
                           '99133',
                           '00010',
                           '00095',
                           '00300',
                           '00400',
                           '63680'), 
           statCd = c('00003', '00008'), 
           startDate = '2010-01-01') 

nwis_data %>%
  filter((is.na(X_.YSI._63680_00003) + is.na(X_.YSI._63680_00003) + is.na(X_.HACH._63680_00003)) < 2)

nwis_tidy <- nwis_data %>%
  select(-contains("cd")) %>%
  transmute(site_no, Date, 
            water_temp = rowMeans(select(., contains("00010")), na.rm = TRUE), # Some variables have different instruments, some of which have character "NA" data
            discharge  = rowMeans(select(., contains("00060")), na.rm = TRUE), # for when they're not reporting measurements. This seemed a straightforward remedy.
            spec_cond  = rowMeans(select(., contains("00095")), na.rm = TRUE),
            dissolv_O  = rowMeans(select(., contains("00300")), na.rm = TRUE),
            pH         = rowMeans(select(., contains("00400")), na.rm = TRUE),
            turbidity  = rowMeans(select(., contains("63680")), na.rm = TRUE),
            nitrate    = rowMeans(select(., contains("99133")), na.rm = TRUE)) %>%
  group_by(site_no, Date) %>%
  summarise(across(.fns = ~ mean(.x, na.rm = TRUE)))

# NWIS Gap Filling--------------------------------------------------------------

nwis_tidy

# NOAA Site Selection-----------------------------------------------------------

ghcnd_sites <- ghcnd_stations() %>%
  filter(first_year < 2010, 
         last_year > 2019, 
         element %in% c("PRCP", "SNOW", "SNWD", "TMAX", "TMIN"),
         latitude > 35,
         latitude < 45,
         longitude > -95,
         longitude < -85)

candidates_meta <- whatNWISsites(siteNumbers = candidates_lengths$site_no)

nearest_sites <- list()

# https://www.r-bloggers.com/2010/11/great-circle-distance-calculations-in-r/
# Calculates the geodesic distance between two lat/long points using the
# Spherical Law of Cosines (slc)
gcd.slc <- function(long1, lat1, long2, lat2) {
  R <- 6371 # Earth mean radius [km]
  p <- pi/180
  d <- acos(sin(lat1*p)*sin(lat2*p) + cos(lat1*p)*cos(lat2*p) * cos(long2*p-long1*p)) * R
  return(d) # Distance in km
}

for (i in 1:nrow(usgs_sites)) {
  
  noaa_sites[[i]] <- station_data %>%
    filter((latitude - usgs_sites$dec_lat_va[i])^2 + 
             (longitude - usgs_sites$dec_long_va[i])^2 == 
             min((latitude - usgs_sites$dec_lat_va[i])^2 +
                   (longitude - usgs_sites$dec_long_va[i])^2)) %>%
    mutate(approx_dist = gcd.slc(longitude, latitude, usgs_sites$dec_long_va[i], usgs_sites$dec_lat_va[i]))
  
}

