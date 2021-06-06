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

Across the 9 sites, the earliest 'dv' data availability of water chemistry variables was 2013-12-05. Data were queried from 2010 onwards to provide sufficient discharge history for our lookback.

Discharge and water temperature are the only two hydrologic variables that we gap-filled so far. Water chemistry variables are considered response variables for the time being, and response variables don't necessarily have to be continuous for an LSTM.

### Discharge

Data coverage for discharge was very good: only 9 missing days between 2010-01-01 and 2021-06-04 for all 9 sites combined. Gaps were all only 1-2 days long. These were filled with simple linear interpolation using `baytrends` ([documentation](https://www.rdocumentation.org/packages/baytrends/versions/2.0.5/topics/fillMissing)). A column named ``"discharge_interp"`` was added to flag interpolated values (``"linear"``).

### Water Temperature 

Water temperature had many more gaps, some of which were several months in length. __We will need to revisit how to fill these gaps__, but for now, I filled 7-day-or-shorter gaps with linear interpolation. Once again a flag column (``"water_temp_interp"``) was added to mark these interpolated values. Longer gaps were filled day-wise with the average of all values collected at that site on that day of the year (``"seasonal"``). These two measures together filled all gaps, though it should be noted that they filled all the way from 2010 to the first measured value with a repeating seasonal pattern.

## GHCND Site Selection and Data Query

For each of the 9 NWIS sites, a list of all GHCND sites collecting one or more variables of interest (listed below) within a geographic projected ellipse (Δlat^2 + Δlon^2 < 0.2) was formed and the approximate distance (km) to the corresponding NWIS site was calculated. This includes sites up to 40-50 km from the NWIS site. Data were pulled from all of these sites from 2010-01-01 to near the present (currently results in a little over half a million GHCND site x day rows).

### Meteorological variables (and GHCND abbreviations)

- Precipitation (PRCP)
- Snow (SNOW)
- Snow depth (SNWD)
- Daily max. temp (TMAX)
- Daily min. temp (TMIN)

Note: TMAX and TMIN were chosen over TAVG as they are available for many more sites.

## GHCND Gap Filling

TMIN, TMAX, and SNWD were filled according to the following protocol:

1. Raw data from the nearest site to each NWIS site were joined to the NWIS data by date.
2. The same linear interpolation method used for NWIS variables was applied.
3. For remaining missing values, the GHCND data was queried for the nearest non-missing measurement for that NWIS site and date (computationally intensive)
4. If gaps remained, the linear interpolation method was applied again.
5. __(HAVEN'T NEEDED THIS YET)__ Last resort: seasonal method as was used for water temperature.

For PRCP and SNOW, the linear interpolation step was left out. I reason that these variables differ from the other three in that one day's value is not nearly as predictive as the next. We'll jump straight to the next-nearest-site-method. This comes at a price in terms of computation but these variables tended to have more data at the nearest site, which my code currently joins efficiently, so it works out OK. 
