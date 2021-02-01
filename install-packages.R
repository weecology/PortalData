# Install pacman if it isn't already installed

if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")


# Install analysis packages using pacman

pacman::p_load(stringr, Hmisc, dplyr, git2r, openxlsx, lubridate, lunar, jsonlite,
               sp, sqldf, raster, RCurl, EML, testthat, htmltab, zoo, tidyr, semver, yaml)

pacman::p_load_gh("16EAGLE/getSpatialData")
pacman::p_load_gh("crubba/htmltab")