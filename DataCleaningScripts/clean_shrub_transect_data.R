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

library(XLConnect)

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

wb = loadWorkbook(newfile)
ws = readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)

splist = read.csv('C:/Users/ellen.bledsoe/Desktop/Git/PortalData/Plants/Portal_plant_species.csv', as.is = T)

plots = seq(24)

# =====================================
# species names not in official list

unique(ws$species[!(ws$species %in% splist$Sp.Code)])

# =====================================
# are all quadrats present

# changes to all plots present and all plot/transect combos present

allquads <-  apply(expand.grid(plots,stakes),1,paste,collapse=' ')
plotquad <-  unique(paste(ws$plot,ws$stake))

