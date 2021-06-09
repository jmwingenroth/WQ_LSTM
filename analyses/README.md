## Data coverage

`coverage_table.r` pulls data from the `download` folder and analyzes the manner in which it was interpolated:

| Value | Explanation |
|------ |-------------|
| `raw` | data values from the NWIS database, unchanged |
| `linear` | gaps in NWIS data filled by linear interpolation along time |
| `seasonal` | gaps in NWIS data filled by mean values at a site for a given DOY |
| `spatial` | spatial interpolation of GHCND values from all nearby stations |
| `spatiotemporal` | gaps in GHCND data filled by linear interpolation along time | 
