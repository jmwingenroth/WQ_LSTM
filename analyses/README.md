## Data coverage

`coverage_table.r` pulls data from `download/` and analyzes the manner in which it was interpolated. Frequencies of different interpolation methods are presented in percent format in `coverage.md`:

| Value | Explanation |
|------ |-------------|
| `Present` | Raw NWIS data values or spatially interpolated GHCND data values |
| `Linear` | Values filled via linear interpolation along the time dimension |
| `Seasonal` | Values filled with the mean value for a given DOY at the site (presently only water temp.) |

See the README.md in `download/` for more information about gap-filling methods.

`coverage_plots.r` plots data with interpolation manner highlighted.
