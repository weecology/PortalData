remove.packages("stringi")
remove.packages("stringr")
install.packages(c("curl",
                   "EML", 
                   "git2r",
                   "Hmisc", 
                   "lwgeom", 
                   "Rcpp",
                   "RCurl",
                   "remotes",
                   "rgdal",
                   "stringi",
                   "stringr",
                   "sf"), type="source", repos="https://cran.rstudio.com")
install.packages('terra', repos='https://rspatial.r-universe.dev')
remotes::install_github("htmltab/htmltab")

# Install analysis packages using pacman
if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")

pacman::p_load(devtools,
               dplyr, 
               jsonlite,
               lubridate, 
               lunar, 
               openxlsx, 
               semver,
               shiny, 
               sp, 
               sqldf, 
               testthat, 
               tidyr, 
               units,
               yaml,
               zoo)
