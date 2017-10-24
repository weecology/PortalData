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

# library(XLConnect) ### Does not work on my computer (RMD).
library(openxlsx)
library(dplyr)

# First manually compare and edit double-entered data 

source('DataCleaningScripts/compare_raw_data.r')

library(openxlsx)
library(dplyr)

season <-  'Summer'
year <-  '2017'
filepath <-  '/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/'

excel_file <-  paste(filepath, "ShrubTransect_", season, year, '.xlsx', sep='')

# load data from excel workbook
ws1 = read.xlsx(excel_file, sheet = 1, colNames = TRUE, na.strings = c('', 'NA', ' '))
ws2 = read.xlsx(excel_file, sheet = 2, colNames = TRUE, na.strings = c('', 'NA', ''))

# if the two worksheets are identical, exit function
if (identical(ws1,ws2)) {                                   
  print('Worksheets identical')
} else {
  unmatched = data.frame(row = c(),column = c())         # empty data frame for storing output
  num_rows = length(ws1$month)
  curr_row = 1
  while (curr_row<=num_rows) {
    v1 = as.character(as.vector(ws1[curr_row,]))          # extract row from worksheet 1
    v2 = as.character(as.vector(ws2[curr_row,]))          # extract row from worksheet 2
    
    # if the two versions of the row are not identical
    if (!identical(v1,v2)) {
      # loop through each element in the row
      col_error = vector()
      for (n in seq(length(v1))) {                        
        if (!identical(v1[n],v2[n])) {
          # add the column name to output vector
          col_error = append(col_error,colnames(ws1)[n])
        }
      }
      # append row and column info to output data frame (curr_row+1 to skip header in excel file)
      unmatched = rbind(unmatched,data.frame(row = curr_row+1,column = col_error))
    }
    curr_row = curr_row+1             # increment index and continue loop
  }
  
}

# iterate through mismatches and fix them
i = 1

i  = i + 1
unmatched[i, ]
ws1[unmatched[i, 'row'] -1 , ]
ws2[unmatched[i, 'row'] - 1, ]

# 
#summer 2017

ws2[1665, 'start'] <- 6790
ws2[1653, 'start'] <- 4970
ws2[1571, 'start'] <- 880
ws1[1548, 'start'] <- 4438
ws2[1541, 'species'] <- 'mimo acul'
ws1[1507, 'start'] <- 3945
ws2[1506, 'height'] <- 32
ws2[1474, 'species'] <- 'mimo acul'
ws1[1470, 'start'] <- 5224
ws1[1416, 'start'] <- 2352
ws2[1375, 'stop'] <- 4105
ws2[1289, 'stop'] <- 2105
ws2[1282, 'stop'] <- 1554
ws1[1269, 'start'] <- 6695
ws2[1235, 'stop'] <- 1685
ws2[1235, 'start'] <- 1670
ws2[1234, 'stop'] <- 1695
ws2[1234, 'start'] <- 1690
ws2[1225, 'start'] <- 6874
ws1[1222, 'stop'] <- 6251
ws1[1222, 'start'] <- 6225
ws1[1210, 'height'] <- 100
ws1[1187, 'stop'] <- 1876
ws2[1122, 'start'] <- 3862
ws2[1105, 'start'] <- 664
ws1[1077, 'stop'] <- 526
ws1[1050, 'stop'] <- 7139
ws2[1049, 'start'] <- 6882
ws1[1043, 'start'] <- 4798
ws2[1040, 'height'] <- 190
ws2[1036, 'start'] <- 2666
ws2[998, 'start'] <- 2371
ws2[660, 'stop'] <- 2185
ws1[660, 'stop'] <- 2185
ws1[951, 'height'] <- 31
ws2[887, 'species'] <- 'lyci ande'
ws2[886, 'species'] <- 'lyci ande'
ws2[871, 'height'] <- 45
ws2[868, 'species'] <- 'guti saro'
ws2[860, 'species'] <- 'mimo acul'
ws2[857, 'species'] <- 'mimo acul'
ws2[844, 'stop'] <- 5287
ws2[841, 'start'] <- 4260
ws2[836, 'start'] <- 2696
ws2[835, 'stop'] <- 2675
ws2[808, 'start'] <- 2960
ws2[786, 'height'] <- 30
ws2[766, 'height'] <- 40
ws2[760, 'species'] <- 'mimo acul'
ws2[699, 'height'] <- 109
ws2[699, 'stop'] <- 2530
ws1[653, 'height'] <- 250
ws1[645, 'start'] <- 6399
ws1[604, 'stop'] <- 5805
ws2[591, 'start'] <- 3882
ws2[587, 'start'] <- 2830
ws1[488, 'start'] <- 2860
ws2[486, 'height'] <- 151
ws2[484, 'stop'] <- 2552
ws1[196, 'stop'] <- 4124
ws2[203, 'start'] <- 4849
ws2[206, 'stop'] <- 5282
ws2[213, 'stop'] <- 6278
ws2[283, 'start'] <- 1994
ws1[291, 'height'] <- 56
ws2[301, 'stop'] <- 4959
ws2[397, 'start'] <- 6838
ws1[471, 'height'] <- 138


# Save matching datasheet
write.csv(ws1, '/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/ShrubTransect_Summer2017_clean.csv', row.names = FALSE)


######################
# 1. Load "clean" .csv file #
######################
ws = read.csv('/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/ShrubTransect_Summer2017_clean.csv', stringsAsFactors= F)
ws$note1 <- NA
######################
# 3. Quality control #
######################

splist <-  read.csv('./Plants/Portal_plant_species.csv', as.is = T)

plots <-  1:24
transects <- c("11", "71")

# =====================================
# species names not in official list

unique(ws$species[!(ws$species %in% splist$speciescode)])

#**ADD valid new species to species list**

# =====================================
# are all transects present

all_trans <-  apply(expand.grid(plots, transects), 1, paste, collapse = ' ') %>% trimws()
plot_trans <-  unique(paste(ws$plot, ws$transect))

# any plot-transect pairs that should be censused that are not in the data
setdiff(all_trans, plot_trans)

# =====================================
# check for valid start, stop and height values

ws[which(!(ws$start %in% 0:7500)), ]   #length of hypotenuse of plots (7000) plus some wiggle room
ws[which(!(ws$stop %in% 0:7500)), ]   
ws[which(!(ws$height %in% 0:400)) , ]

ws[ which(ws$stop < ws$start), ]

# fix errors
# summer 2017
ws[1378, 'stop'] <- 4684
ws[1378, 'note1'] <- 1
ws[233, 'stop'] <- 2771
ws[233, 'note1'] <- 1
ws[1612, 'start'] <- 5425
ws[1612, 'stop'] <- 5428
ws[1612, 'note1'] <- 2

# =====================================
# save cleaned up version to Dropbox

# make sure you are saving the most up-to-date version of the file
#ws <-  readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)
filepath = '/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/'
season = 'summer'
year = 2017
write.csv(ws, file = paste(filepath, "ShrubTransect_", season, year, "_clean", ".csv", sep = ''), 
          row.names = FALSE, na = "")

#################################################
# 4. Append new data to 2015+ plant data in Git #
#################################################

data_append <- ws[, c("year", "month", "day", "plot", "transect", "species", "start", "stop", "height", "notes", "note1")]

# append to existing data file
write.table(data_append, file = "./Plants/Portal_plant_transects_2015_present.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")



# 
#  
# transects = read.csv('/Users/renatadiaz/Documents/GitHub/PortalData/Plants/Portal_plant_transects_2015_present.csv')
# 
# transects$diff = transects$stop - transects$start
# 
# transects[ which(transects$diff < 0), ]
# 
# transects[1389, 'stop'] <- 5955
# transects[1389, 'start'] <- 5572
# transects[1389, 'note1'] <- 2
# 
# transects[2368, c('start', 'stop', 'note1')] <- c(4585, 4666, 2)
# transects[2832, c('stop', 'note1')] <- c(6142, 1)
# transects[3059, c('start', 'stop', 'note1')] <- c(2342, 2378, 2)
# transects[3060, c('start', 'stop', 'note1')] <- c(2342, 2388, 2)
# transects[3123, c('start', 'stop', 'note1')] <- c(6440, 6456, 2)

# 
#tail(transects)
# 
# transects$note1 <- NA
# write.table(transects, file = "./Plants/Portal_plant_transects_2015_present.csv", 
             row.names = F, col.names = T, na = "", append = F, sep = ",")
