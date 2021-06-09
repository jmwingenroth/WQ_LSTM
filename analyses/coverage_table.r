library(tidyverse)
library(knitr)

hydro <- read_csv(file = "download/hydro_filled.csv", col_types = "cDdddddddccd")
meteo <- read_csv(file = "download/meteo_filled.csv")

joined <- cbind(hydro, meteo) %>%
  select(-date, -nwis_site) %>%
  tibble()

interp <- joined[str_detect(names(joined), "interp")]

groups <- lapply(colnames(interp), as.symbol)

tables <- list()

for (i in 1:length(groups)) {
  
  tables[[i]] <- interp %>%
    group_by_(.dots = groups[i]) %>%
    summarise(count = n(), percent = 100*n()/nrow(interp))
  
}

writeLines(kable(tables), con = "analyses/coverage.md")