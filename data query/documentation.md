## Data Sources 

Data were retrieved from the USGS National Water Information System (NWIS) dataset using the `dataRetrieval` package and from the NOAA Global Historical Climate Network Daily (GHCND) dataset using the `rnoaa` package (both are R packages).

## NWIS Site Selection

All 50 states were screened for sites possessing daily measurements (`service = 'dv'`) of mean (`statCd = "00003"`) nitrate/nitrite concentration values (`parmCd = "99133"`). This returned 132 sites. From these, sites not appearing on a list of delineated watersheds provided by Galen were removed. This left 48 sites with delineated watersheds. Sites with fewer than 1000 days of discharge data, or fewer than 500 days of any of the six other variables of interest (listed below) were removed, leaving 14 sites. Of these, 10 were in the Midwest ([part numbers](https://help.waterdata.usgs.gov/faq/sites/do-station-numbers-have-any-particular-meaning) 03 through 06), whereas 4 were around the East Coast (part numbers 01 and 02). We chose to initially focus on sites in the Midwest. Lastly, one of these 10 sites (USGS ID: 05599490) was removed because it had its catchment delineated in a separate USGS dataset and thus lacked some attributes calculated for the other 9.

### Hydrologic variables (and NWIS parameter codes)

- Discharge (00060)
- Water temperature (00010)
- Nitrate/nitrite concentration (99133)
- Specific conductance (00095)
- Dissolved oxygen (00300)
- pH (00400)
- Turbidity (63680)

## NWIS Data Query and Gap Filling

Across the 9 sites, the earliest 'dv' data availability of water chemistry variables was around 2014. Data was queried from 2010 onwards to provide sufficient discharge history for our lookback.

Discharge and water temperature are the only two hydrologic variables that we gap-filled. Water chemistry variables are considered response variables for the time being, and response variables don't necessarily have to be continuous for an LSTM.

### Discharge

### Water Temperature 

## GHCND Site Selection

All GHCND stations with data collected before 2010 and after 2019 for one or more variables of interest (listed below) were considered eligible. For each of the 9 NWIS sites, meteorological data were retrieved from the nearest eligible GHCND site.

### meteorological variables (and GHCND abbreviations)

- Precipitation (PRCP)
- Snow (SNOW)
- Snow depth (SNWD)
- Daily max. temp (TMAX)
- Daily min. temp (TMIN)

Note: TMAX and TMIN were chosen over TAVG as they are available for many more sites.
