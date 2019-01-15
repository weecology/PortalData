# Clean Shrub Transect Data
# most of the code taken from EMC
# organized by EKB
# May 11, 2016
# refactored 4/24/18 EMC

# Notes:
#   Section 1
#     * a. Ensure season, year, and filepath are correct *
#   Section 2
#       a. check double-entered data [general_data_cleaning_functions.R]
#   Section 3
#     * a. Ensure that species list path is correct *
#   Section 4
#       a. ONLY DO THIS ONCE!
#     * b. Ensure the file path is correct *

#####################################################################################

library(openxlsx)
library(dplyr)
source('DataCleaningScripts/general_data_cleaning_functions.R')
source('DataCleaningScripts/plant_data_cleaning_functions.R')

######################
# 1. Load Excel file #
######################
season <-  'Summer'
year <-  '2018'
filepath <-  '~/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/'

excel_file <-  paste(filepath, "ShrubTransect_", season, year, '.xlsx', sep='')

##################################
# 2. Compare double-entered data #
##################################

unmatched = compare_worksheets(excel_file)

# iterate through mismatches and fix them
ws1 = openxlsx::read.xlsx(excel_file, sheet = 1, colNames = TRUE, na.strings = '')
ws2 = openxlsx::read.xlsx(excel_file, sheet = 2, colNames = TRUE, na.strings = '')

i = 1

i  = i + 1
unmatched[i, ]
ws1[unmatched[i, 'row'] -1 , ]
ws2[unmatched[i, 'row'] - 1, ]

# Save matching datasheet
write.csv(ws1, '~/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/ShrubTransect_Summer2018_clean.csv', row.names = FALSE)

######################
# 3. Quality control #
######################

ws = read.csv('~/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/ShrubTransect_Summer2018_clean.csv', stringsAsFactors= F)

splist = read.csv('Plants/Portal_plant_species.csv',as.is=T)

transect_data_quality_checks(ws,splist)


# fix any errors, save cleaned version to dropbox


#################################################
# 4. Append new data to 2015+ plant data in Git #
#################################################

data_append <- ws[, c("year", "month", "day", "plot", "transect", "species", "start", "stop", "height", "notes")]

# append to existing data file
write.table(data_append, file = "Plants/Portal_plant_transects_2015_present.csv",
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")


# =====================================
# old code: these checks have been incorporated into transect_data_quality_checks(), leaving them here for reference
# =====================================
# are all transects present

#all_trans <-  apply(expand.grid(plots, transects), 1, paste, collapse = ' ') %>% trimws()
#plot_trans <-  unique(paste(ws$plot, ws$transect))

# any plot-transect pairs that should be censused that are not in the data
#setdiff(all_trans, plot_trans)

# -----------------------------------------
# check for valid start, stop and height values

#ws[which(!(ws$start %in% 0:7500)), ]   #length of hypotenuse of plots (7000) plus some wiggle room
#ws[which(!(ws$stop %in% 0:7500)), ]
#ws[which(!(ws$height %in% 0:400)) , ]

#ws[ which(ws$stop < ws$start), ]

# fix errors

# ---------------------------------------
# save cleaned up version to Dropbox

# make sure you are saving the most up-to-date version of the file
#ws <-  readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)
#filepath = '~/PortalData/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/'
#season = 'summer'
#year = 2017
#write.csv(ws, file = paste(filepath, "ShrubTransect_", season, year, "_clean", ".csv", sep = ''),
#          row.names = FALSE, na = "")

# --------------------------------------
#
# transects = read.csv('~/PortalData/Plants/Portal_plant_transects_2015_present.csv')
# transects$notes[which(!is.na(transects$note1))] <- transects$note1[which(!is.na(transects$note1))]
# transects[645, 'notes'] <- NA
# transects[1345:1351, 'notes'] <- 3
# transects$notes <- NA
# unique(transects$notes)
# transects <- transects[,1:10]
#
# head(transects)#
# transects$diff = transects$stop - transects$start
#
# transects[ which(transects$diff < 0), ]
#
# transects[1389, 'stop'] <- 5955
# transects[1389, 'start'] <- 5572
# transects[1389, 'note'] <- 2
#
# transects[2368, c('start', 'stop', 'note1')] <- c(4585, 4666, 2)
# transects[2832, c('stop', 'note')] <- c(6142, 1)
# transects[3059, c('start', 'stop', 'note')] <- c(2342, 2378, 2)
# transects[3060, c('start', 'stop', 'note')] <- c(2342, 2388, 2)
# transects[3123, c('start', 'stop', 'note')] <- c(6440, 6456, 2)

#
#tail(transects)
#
# transects$note<- NA
# write.table(transects, file = "./Plants/Portal_plant_transects_2015_present.csv",
#              row.names = F, col.names = T, na = "", append = F, sep = ",")
