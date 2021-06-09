## Data coverage

`coverage_table.r` pulls data from `download/` and analyzes the manner in which it was interpolated. Values are presented in `coverage.md`:

| Value | Explanation |
|------ |-------------|
| `raw` | data values from the NWIS database, unchanged |
| `linear` | gaps in NWIS data filled by linear interpolation along time |
| `seasonal` | gaps in NWIS data filled by mean values at a site for a given DOY |
| `spatial` | spatial interpolation of GHCND values from all nearby stations |
| `zeroed`  | gaps in GHCND data filled with zeros |
| `spatiotemporal` | gaps in GHCND data filled by linear interpolation along time | 

See the README.md in `download/` for more information about gap-filling methods.
