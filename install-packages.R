# Install pacman if it isn't already installed

if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")


# Install analysis packages using pacman

pacman::p_load(stringr, Hmisc, dplyr, git2r, openxlsx, lubridate, lunar, jsonlite, devtools,
               sp, sqldf, raster, RCurl, EML, testthat, htmltab, zoo, tidyr, semver, yaml)

pacman::p_load_gh("16EAGLE/getSpatialData")
devtools::install_url('https://cran.r-project.org/src/contrib/Archive/htmltab/htmltab_0.7.1.1.tar.gz')