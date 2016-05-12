# Clean Shrub Transect Data 
# most of the code taken from EMC
# organized by EKB
# May 11, 2016

# Notes:
#   Section 1
#     * a. Ensure season, year, and filepath are correct *
#   Section 2
#       a. Source code from rodent checking (EMC)
#   Section 3
#     * a. Ensure that species list path is correct *
#   Section 4
#       a. ONLY DO THIS ONCE!
#     * b. Ensure the file path is correct *

#####################################################################################

library(XLConnect)
library(dplyr)

source('compare_raw_data.r')

######################
# 1. Load Excel file #
######################

season <-  'Summer'
year <-  '2015'
filepath <-  'C:/Users/ellen.bledsoe/Dropbox/Portal/PORTAL_primary_data/Plant/Transects/ShrubTransects(2015-present)/Rawdata/'

newfile <-  paste(filepath, "ShrubTransect_", season, year, '.xlsx', sep='')

##################################
# 2. Compare double-entered data #
##################################

compare_worksheets(newfile)

######################
# 3. Quality control #
######################

wb <-  loadWorkbook(newfile)
ws <-  readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)

splist <-  read.csv('C:/Users/ellen.bledsoe/Desktop/Git/PortalData/Plants/Portal_plant_species.csv', as.is = T)

plots <-  1:24
transects <- c("T1", "T2")

# =====================================
# species names not in official list

unique(ws$species[!(ws$species %in% splist$Sp.Code)])

# =====================================
# are all transects present

all_trans <-  apply(expand.grid(plots, transects), 1, paste, collapse = ' ') %>% trimws()
plot_trans <-  unique(paste(ws$plot, ws$transect))

# any plot-transect pairs that should be censused that are not in the data
setdiff(all_trans, plot_trans)

# =====================================
# save cleaned up version to Dropbox

# make sure you are saving the most up-to-date version of the file
ws <-  readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)

write.csv(ws, file = paste(filepath, "ShrubTransect_", season, year, "_clean", ".csv", sep = ''), 
          row.names = FALSE, na = "")

#################################################
# 4. Append new data to 2015+ plant data in Git #
#################################################

data_append <- data_clean[, c("year", "month", "day", "transect", "plot", "location", "species", "height", "notes")]

# append to existing data file
write.table(data_append, file = "C:/Users/ellen.bledsoe/Desktop/Git/PortalData/Plants/Portal_plant_transects_2015_present.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

