library(tidyverse)
library(knitr)

hydro <- read_csv(file = "download/hydro_filled.csv", col_types = "cDdddddddccd")
meteo <- read_csv(file = "download/meteo_filled.csv")

joined <- cbind(hydro, meteo) %>%
  select(-date, -nwis_site) %>%
  tibble()

table <- joined %>%
  pivot_longer(cols = contains("interp"), names_to = "variable", values_to = "interpolation") %>%
  mutate(variable = str_sub(variable,,-8)) %>%
  group_by(site_no, variable, interpolation) %>%
  summarise(n = n()) %>%
  pivot_wider(names_from = interpolation, values_from = n) %>%
  ungroup() %>%
  rowwise() %>%
  transmute(Site = site_no, 
            Variable = variable,
            datespan = as.numeric(max(joined$Date) - min(joined$Date) + 1),
            "Present (%)"  = 100*sum(raw, spatial, na.rm = TRUE)/datespan,
            "Linear (%)"   = 100*sum(linear, spatiotemporal, zeroed, na.rm = TRUE)/datespan,
            "Seasonal (%)" = 100*seasonal/datespan) %>%
  replace_na(replace = list(Zeros = 0, Seasonal = 0)) %>%
  mutate(across(contains("%"), function (x) round(x, digits = 1))) %>%
  select(-datespan)

table$Site[duplicated(table$Site)] <- ""

writeLines(kable(table), con = "analyses/coverage.md")
