# Install pacman if it isn't already installed

if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")

install.packages("RCurl", type="source", repos="https://cran.rstudio.com")
install.packages("curl", type="source", repos="https://cran.rstudio.com")
install.packages("stringi", type="source", repos="https://cran.rstudio.com")
install.packages("rgdal", type="source", repos="https://cran.rstudio.com")
install.packages("sf", type="source", repos="https://cran.rstudio.com")
install.packages("Hmisc", type="source", repos="https://cran.rstudio.com")
# Install analysis packages using pacman

pacman::p_load(units, sf, shiny, stringi, stringr, Hmisc, dplyr, git2r, openxlsx, lubridate, lunar, jsonlite, 
               devtools, sp, sqldf, raster, EML, testthat, zoo, tidyr, semver, yaml)

pacman::p_load_gh("16EAGLE/getSpatialData")
devtools::install_url('https://cran.r-project.org/src/contrib/Archive/htmltab/htmltab_0.7.1.1.tar.gz')
