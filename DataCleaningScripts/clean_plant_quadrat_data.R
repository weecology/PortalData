# Clean Plant Quadrat Data
# most of the code taken from EMC
# organized by EKB
# May 10, 2016
# updated 4/23/18 by EMC
 
# Notes:
#   Section 1
#       a. Season and year should be changed accordingly
#     * b. Make sure filepath is assigned to the appropriate directory *
#       c. Use the most up-to-date version of the species list from GitHub
#   Section 2
#       a. From general_data_cleaning_functions.R
#   Section 3
#       a. This code is taken from EMC's "clean_plant_2014_2015.r
#       b. QC code in plant_data_cleaning_functions.R
#       c. Add new species to "Portal_plant_species.csv"
#   Section 4
#     * a. Make sure to check directory for appending the existing file *

library(dplyr)
source('DataCleaningScripts/general_data_cleaning_functions.R')
source('DataCleaningScripts/plant_data_cleaning_functions.R')

######################
# 1. Load Excel file #
######################

season <-  'Winter'
year <-  '2019'
filepath <-  '~/Dropbox/Portal/PORTAL_primary_data/Plant/Quadrats/Dataraw/Newdata/'

newfile <-  paste(filepath, season, year, '.xlsx', sep='')

##################################
# 2. Compare double-entered data #
##################################

splist = read.csv('./Plants/Portal_plant_species.csv',as.is=T)

unmatched = compare_worksheets(newfile)

# iterate through mismatches and fix them
ws1 = openxlsx::read.xlsx(newfile, sheet = 1, colNames = TRUE, na.strings = '')
ws2 = openxlsx::read.xlsx(newfile, sheet = 2, colNames = TRUE, na.strings = '')

i = 1

i  = i + 1
unmatched[i, ]
ws1[unmatched[i, 'row'] -1 , ]
ws2[unmatched[i, 'row'] - 1, ]

# Save matching datasheet
savepath = paste0('~/Dropbox/Portal/PORTAL_primary_data/Plant/Quadrats/Dataraw/Newdata/', season, year, '_matched.csv')
write.csv(ws1, savepath, row.names = FALSE)

######################
# 3. Quality control #
######################

ws = read.csv(savepath, stringsAsFactors = F)

ws$notes = NA

quadrat_data_quality_checks(ws, splist = splist)



# ====================================
# remove empty quadrats

data_clean <- remove_empty_quads(ws)

# ====================================
# check for missing data
fields = c('year','month','day','season','plot','quadrat','species','abundance','cover')

missingdat = check_missing_data(data_clean,fields)
if (length(missingdat)>0) {print(paste('missing data in row: ',paste(missingdat,collapse='  ')))}

# =====================================
# correct all of the data types

data_clean$year <- as.integer(data_clean$year)
data_clean$month <- as.integer(data_clean$month)
data_clean$day <- as.integer(data_clean$day)
data_clean$season <- noquote(as.factor(data_clean$season))
data_clean$plot <-   as.integer(data_clean$plot)
data_clean$quadrat <- as.integer(data_clean$quadrat)
data_clean$species <- as.factor(data_clean$species)
data_clean$abundance <- as.integer(data_clean$abundance)
data_clean$cover <- as.numeric(data_clean$cover)
data_clean$cf <- as.factor(data_clean$cf)
data_clean$notes <- as.integer(data_clean$notes)

# =====================================
# Add census to census dates table
dates = read.csv('Plants/Portal_plant_census_dates.csv')

if(!(unique(paste(data_clean$year,data_clean$season)) %in% paste(dates$year,dates$season))) {

start_month = min(data_clean$month)
end_month = max(data_clean$month)
start_day = min(data_clean$day[which(data_clean$month == start_month)])
end_day = max(data_clean$day[which(data_clean$month == end_month)])
newrow = cbind(unique(data_clean[,c('year','season')]), censusdone = 'yes', start_month = start_month, start_day = start_day, end_month = end_month, end_day = end_day)
# append to existing dates file
write.table(newrow, file = "Plants/Portal_plant_census_dates.csv",
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",", quote = FALSE)
}

# =====================================
# save cleaned up version to Dropbox

write.csv(data_clean, file = paste(filepath, season, year, "_clean", ".csv", sep = ''),
          row.names = FALSE, na = "")

#################################################
# 4. Append new data to 2015+ plant data in Git #
#################################################

data_append <- data_clean[, c("year", "season", "plot", "quadrat", "species", "abundance", "cover", "cf", "notes")]

# append to existing data file
write.table(data_append, file = "Plants/Portal_plant_quadrats.csv",
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")
