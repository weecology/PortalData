# Install pacman if it isn't already installed

if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")


# Install analysis packages using pacman

pacman::p_load(stringr, Hmisc, dplyr, XLConnect, lubridate, sqldf, RCurl, EML, testthat)
