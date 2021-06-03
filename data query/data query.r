library(tidyverse)
library(rnoaa) #NOAA GHCND meteorological data queries
library(dataRetrieval) # USGS NWIS hydrologic data queries

# USGS Site Selection-----------------------------------------------------------

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

candidate_sites <- left_join(data_avail, parm_key, by = c("parm_cd" = "parameter_cd")) %>%
  mutate(parm = str_sub(parameter_nm,,7)) %>%
  filter(! parm %in% c("Elevati", "Gage he")) %>%
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

# NOAA Site Selection-----------------------------------------------------------

