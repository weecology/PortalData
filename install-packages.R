# Install pacman if it isn't already installed

if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")


# Install analysis packages using pacman

pacman::p_load(stringr, Hmisc, dplyr, git2r, openxlsx, lubridate, lunar,
               sqldf, RCurl, EML, testthat, htmltab, zoo, tidyr, semver, yaml)
