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

library(openxlsx)
library(dplyr)


######################
# 1. Load Excel file #
######################

season <-  'Summer'
year <-  '2017'
filepath <-  '/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/Quadrats/Dataraw/Newdata/'

newfile <-  paste(filepath, season, year, '.xlsx', sep='')

##################################
# 2. Compare double-entered data #
##################################
excel_file = newfile
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

# Save matching datasheet
write.csv(ws1, '/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/Quadrats/Dataraw/Newdata/Summer2017_matched.csv', row.names = FALSE)

######################
# 3. Quality control #
######################

ws = read.csv('/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/Quadrats/Dataraw/Newdata/Summer2017_matched.csv', stringsAsFactors = F)

ws$notes <- NA

splist = read.csv('./Plants/Portal_plant_species.csv',as.is=T)

plots = seq(24)
stakes = c(11,13,15,17,31,33,35,37,51,53,55,57,71,73,75,77)

# =====================================
# species names not in official list

new.names = setdiff(ws$species,splist$speciescode)



#**ADD valid new species to species list**

# =====================================
# are all quadrats present

allquads <-  apply(expand.grid(plots,stakes),1,paste,collapse=' ')
plotquad <-  unique(paste(ws$plot,ws$quadrat))

# any plot-stake pairs in the data that are not supposed to be censused
setdiff(plotquad,allquads)

# any plot-stake pairs that should be censused that are not in the data
setdiff(allquads,plotquad)
# 



# =====================================
# are there any duplicate entries of plot/quadrat/species

ws[(duplicated(paste(ws$plot, ws$quadrat, ws$species))),]
# 

# =====================================
# are there any plants recorded in an "empty" quadrat

empties <-  ws[ws$abundance == 0,]
ws[(paste(ws$plot,ws$quadrat) %in% paste(empties$plot,empties$quadrat)),]

which(ws$abundance == 0)


# ====================================
# remove empty quadrats

data_clean <- ws[!is.na(ws$species),]

# ====================================
# any empty data cells

data_clean[is.na(data_clean$abundance),]
data_clean[is.na(data_clean$species),]
data_clean[is.na(data_clean$cover),]

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
dates = read.csv('./Plants/Portal_plant_census_dates.csv')

if(!(unique(paste(data_clean$year,data_clean$season)) %in% paste(dates$year,dates$season))) {
  
newdates = as.Date(with(data_clean, paste(year, month, day, sep="-")), "%Y-%m-%d")
newrow = cbind(unique(data_clean[,c('year','season')]), censusdone = 'yes', start = format(min(newdates),"%m-%d"), end = format(max(newdates),"%m-%d"))
# append to existing dates file
write.table(newrow, file = "./Plants/Portal_plant_census_dates.csv", 
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
write.table(data_append, file = "./Plants/Portal_plant_quadrats.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

# data_old = read.csv("./Plants/Portal_plant_quadrats.csv", stringsAsFactors = F)
