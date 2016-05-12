# Clean Plant Quadrat Data 
# most of the code taken from EMC
# organized by EKB
# May 10, 2016

# Notes:
#   Section 1 
#       a. Season and year should be changed accordingly
#     * b. Make sure filepath is assigned to the appropriate directory *
#       c. Use the most up-to-date version of the species list from GitHub
#   Section 2
#       a. This source code is take from the rodent data QC (EMC)
#   Section 3
#       a. This code is taken from EMC's "clean_plant_2014_2015.r
#     * b. Make sure to check directory for splist *
#       c. Add new species to "Portal_plant_species.csv"
#   Section 4
#     * a. Make sure to check directory for appending the existing file *

library(XLConnect)

source('compare_raw_data.r')

######################
# 1. Load Excel file #
######################

season <-  'Winter'
year <-  '2016'
filepath <-  'C:/Users/ellen.bledsoe/Dropbox/Portal/PORTAL_primary_data/Plant/Quadrats/Dataraw/2015_data/'

newfile <-  paste(filepath, season, year, '.xlsx', sep='')

##################################
# 2. Compare double-entered data #
##################################

compare_worksheets(newfile)

######################
# 3. Quality control #
######################

wb = loadWorkbook(newfile)
ws = readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)

splist = read.csv('C:/Users/ellen.bledsoe/Desktop/Git/PortalData/Plants/Portal_plant_species.csv',as.is=T)

plots = seq(24)
stakes = c(11,13,15,17,31,33,35,37,51,53,55,57,71,73,75,77)

# =====================================
# species names not in official list

unique(ws$species[!(ws$species %in% splist$Sp.Code)])

# =====================================
# are all quadrats present

allquads <-  apply(expand.grid(plots,stakes),1,paste,collapse=' ')
plotquad <-  unique(paste(ws$plot,ws$stake))

# any plot-stake pairs in the data that are not supposed to be censused
setdiff(plotquad,allquads)

# any plot-stake pairs that should be censused that are not in the data
setdiff(allquads,plotquad)

# =====================================
# are there any duplicate entries of plot/quadrat/species

ws[(duplicated(paste(ws$plot, ws$stake, ws$species))),]

# =====================================
# are there any plants recorded in the same quadrat as a "none"

nones <-  ws[ws$species == 'none',]
ws[(paste(ws$plot,ws$stake) %in% paste(nones$plot,nones$stake)),]

# ====================================
# any empty data cells

ws[is.na(ws$abundance),]
ws[is.na(ws$species),]

# =====================================
# save cleaned up version to Dropbox

data_clean <- ws[!is.na(ws$species),]

write.csv(data_clean, file = paste(filepath, season, year, "_clean", ".csv", sep = ''), 
          row.names = FALSE, na = "")

#################################################
# 4. Append new data to 2015+ plant data in Git #
#################################################

data_append <- data_clean[, c("year", "season", "plot", "quadrat", "species", "abundance", "cover", "cf")]

# append to existing data file
write.table(data_append, file = "C:/Users/ellen.bledsoe/Desktop/Git/PortalData/Plants/Portal_plant_2015_present.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")
