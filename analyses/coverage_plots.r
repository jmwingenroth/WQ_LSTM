library(tidyverse)

hydro <- read_csv(file = "download/hydro_filled.csv", col_types = "cDdddddddccd")
meteo <- read_csv(file = "download/meteo_filled.csv")

joined <- cbind(hydro, meteo) %>%
  select(-date, -nwis_site) %>%
  tibble()

colnames(joined)

vars <- c("water_temp",
          "discharge",
          "prcp",
          "snow",
          "snwd",
          "tmax",
          "tmin")

plots <- list()

for (i in 1:length(vars)) {
  
  plots[[i]] <- joined %>%
    ggplot(aes_string(x = "Date", y = vars[i], size = paste0(vars[i], "_interp"), color = paste0(vars[i], "_interp"))) +
    geom_line(inherit.aes = FALSE, aes_string(x = "Date", y = vars[i]), alpha = .5) +
    geom_point() +
    facet_wrap(~site_no, scales = "free_y") +
    scale_size_manual(values = c("linear" = 3, "raw" = .5, "seasonal" = 1, "zeroed" = 3, "spatial" = .5, "spatiotemporal" = 3))
  
  ggsave(paste0("analyses/coverage_plots/",vars[i],".png"), plots[[i]], dpi = 100, width = 9, height = 7)
  
}
