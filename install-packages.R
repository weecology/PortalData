# Install pacman if it isn't already installed

if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")

remove.packages("stringi")
remove.packages("stringr")
install.packages(c("Rcpp","stringi","stringr","RCurl","curl","Hmisc", "EML", "sf","rgdal","lwgeom", "git2r"), type="source", repos="https://cran.rstudio.com")
install.packages('terra', repos='https://rspatial.r-universe.dev')

# Install analysis packages using pacman

# pacman::p_load(units, sf, rgdal, lwgeom, shiny, stringi, stringr, Hmisc, dplyr, git2r, openxlsx, lubridate, htmltab, 
#                lunar, jsonlite, devtools, sp, sqldf, raster, RCurl, EML, testthat, zoo, tidyr, semver, yaml)
               

pacman::p_load(units, shiny, dplyr, openxlsx, lubridate, htmltab, 
               lunar, jsonlite, devtools, sp, sqldf, raster, testthat, zoo, tidyr, semver, yaml)
