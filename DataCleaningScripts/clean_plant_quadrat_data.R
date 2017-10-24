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

ws2[877, 'species'] <- 'ambr arte'
ws2[2194, 'abundance'] <- 21
ws2[1800, 'abundance'] <- 0
ws2[782, 'abundance'] <- 0
ws2[753, 'abundance'] <- 0
ws2[265, 'cover'] <- .1
ws1[2607, 'species'] <- 'acac palm'
ws1[2591, 'cover'] <- .1
ws1[2542, 'cover'] <- 5
ws1[2541, 'cover'] <- 5
ws1[2483, 'cf'] <- NA
ws2[2453, 'abundance'] <- 18
ws1[2418, 'species'] <- 'kall hirt'
ws2[2357, 'cover'] <- 1
ws2[2356, 'cover'] <- 1
ws1[2294, 'cf'] <- 'dale brac'
ws2[2292, 'quadrat'] <- 75
ws1[2290, 'cf'] <- 'dale brac'
ws1[2282, 'cf'] <- 'dale brac'
ws1[2279, 'cf'] <- 'dale brac'
ws1[2272, 'cf'] <- 'dale brac'
ws1[2264, 'cf'] <- 'dale brac'
ws2[2257:2262, 'plot'] <- 11
ws2[2256, 'quadrat'] <- 37
ws2[2253, 'quadrat'] <- 35
ws1[2232, 'cover'] <- 1
ws1[2227, 'cf'] <-'dale brac'
ws2[2184, 'abundance'] <- 2
ws1[2181, 'cover'] <- 1
ws1[2174:2179, 'quadrat'] <- 35
ws1[2166, 'cf'] <- NA
ws2[2160:2186, 'plot'] <- 12
ws1[2148, 'cf'] <- NA
ws1[2140, 'cf'] <- NA
ws1[2103, 'cf'] <- NA
ws1[2100, 'cover'] <- 1
ws2[2081, 'abundance'] <- 5
ws2[2074, 'cover'] <- .1
ws1[2013, 'cf'] <- NA
ws1[2002, 'cf'] <- NA
ws1[1982, 'cf'] <- NA
ws1[1973, 'cf'] <- NA
ws1[1843, 'cover'] <- 1
ws1[1805, 'cover'] <- 1
ws1[1785, 'cf'] <- 'chlo virg erio lemm pani mili'
ws1[1752, 'cover'] <- 3
ws1[1751, 'cover'] <- .1
ws1[1748, 'cover'] <- 1
ws1[1747, 'cover'] <- 1
ws1[1725, 'cover'] <- .1
ws1[1723, 'cover'] <- .1
ws1[1661, 'cf'] <- NA
ws2[1658:1660, 'quadrat'] <- 37
ws2[269, 'cover'] <- .1
ws2[267, 'cover'] <- .1
ws2[266, 'cover'] <- .1
ws2[265, 'cover'] <- .1
ws2[264, 'cover'] <- .1
ws2[263, 'cover'] <- .1
ws2[1609, 'species'] <- 'erag lehm'
ws2[1589, 'species'] <- 'moll cerv'
ws2[1531, 'abundance'] <- 5
ws2[1523, 'cover'] <- 1
ws2[1502, 'cover'] <- 1
ws2[1488, 'cover'] <- 1
ws1[1388, 'cf'] <- NA
ws2[1362, 'abundance'] <- 27
ws1[1140, 'cover'] <- 1
ws2[1119, 'cover'] <- 1
ws1[1038, 'abundance'] <- 2
ws1[1025, 'cover'] <- 1
ws2[992, 'cover'] <- 50
ws2[991, 'cover'] <- .1
ws1[974, 'cover'] <- 1
ws1[967, 'cover'] <- 1
ws1[964, 'cover'] <- 1
ws2[951, 'cover'] <- 1
ws1[857:866, 'plot'] <- 10
ws1[791, 'abundance'] <- 3
ws1[601, 'species'] <- 'euph serr'
ws1[550, 'cover'] <- 1
ws1[375, 'species'] <- 'euph serp'
ws1[341, 'cover'] <- 1
ws1[231, 'abundance'] <- 12
ws1[213, 'species'] <- 'erag lehm'
ws2[178, 'abundance'] <- 26
ws2[144, 'cover'] <- .1
ws2[142, 'cover'] <- .1
ws2[142, 'cf'] <- 'dale brac'
ws2[136, 'abundance'] <- 16
ws1[122, 'cover'] <- 1
ws1[87, 'abundance'] <- 1
ws1[80, 'cf'] <- 'dale brac'
ws2[41, 'abundance'] <- 64
ws1[34, 'cf'] <- 'dale brac'
ws2[30, 'cover'] <- 25
ws2[30, 'species'] <- 'erag lehm'
ws1[7, 'cf'] <- 'dale brac'


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

# NAs can stay because they will be removed later
ws[which(is.na(ws$species)), ]

ws[which(ws$species == new.names[2]), 'species'] <- 'atri cane'
ws[which(ws$species == new.names[3]), 'species'] <- 'kall hirs'
ws[which(ws$species == new.names[4]), c('species', 'notes')] <- c('amar palm', 1)



#**ADD valid new species to species list**

# =====================================
# are all quadrats present

allquads <-  apply(expand.grid(plots,stakes),1,paste,collapse=' ')
plotquad <-  unique(paste(ws$plot,ws$quadrat))

# any plot-stake pairs in the data that are not supposed to be censused
setdiff(plotquad,allquads)

# any plot-stake pairs that should be censused that are not in the data
setdiff(allquads,plotquad)

which(ws$plot == 12)
ws[2174:2179, 'quadrat'] <- 33
ws[2174:2179, 'notes'] <- 2

# plot 24 stake 51 - skipped, or empty?


# =====================================
# are there any duplicate entries of plot/quadrat/species

ws[(duplicated(paste(ws$plot, ws$quadrat, ws$species))),]

filter(ws, year == 2017, plot == 4, quadrat == 37, species == 'pani sp')
# =====================================
# are there any plants recorded in an "empty" quadrat

empties <-  ws[ws$abundance == 0,]
ws[(paste(ws$plot,ws$quadrat) %in% paste(empties$plot,empties$quadrat)),]


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

data_append <- data_clean[, c("year", "season", "plot", "quadrat", "species", "abundance", "cover", "cf")]

# append to existing data file
write.table(data_append, file = "./Plants/Portal_plant_quadrats.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",", quote = FALSE)
