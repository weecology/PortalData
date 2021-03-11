# Install pacman if it isn't already installed

if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")

remove.packages("stringi")
remove.packages("stringr")
install.packages(c("stringi","stringr","RCurl","curl","Hmisc", "EML", "sf","rgdal","lwgeom", "git2r", ), type="source", repos="https://cran.rstudio.com")

# Install analysis packages using pacman

pacman::p_load(units, sf, rgdal, lwgeom, shiny, stringi, stringr, Hmisc, dplyr, git2r, openxlsx, lubridate, 
               lunar, jsonlite, devtools, sp, sqldf, raster, RCurl, EML, testthat, zoo, tidyr, semver, yaml)

pacman::p_load_gh("16EAGLE/getSpatialData")
devtools::install_url('https://cran.r-project.org/src/contrib/Archive/htmltab/htmltab_0.7.1.1.tar.gz')
