# This script is for cleaning new rodent data.  Data must first be entered in two separate sheets in
# an excel file, by two different people to reduce entry error.

library(XLConnect)
library(sqldf)
library(RCurl)
library(dplyr)

source('compare_raw_data.r')
source('rodent_data_cleaning_functions.R')
source('new_moon_numbers.R')

# set your working directory
setwd("~bleds22e/Documents/Git/PortalData/")

##############################################################################
# New file to be checked
##############################################################################

newperiod = '462'
filepath = '~bleds22e/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/'

newfile = paste(filepath, 'newdat', newperiod, '.xlsx', sep = '')
scannerfile = paste(filepath, 'tag scans/tags', newperiod, '.txt', sep = '')

##############################################################################
# 1. Compare double-entered data -- will return 'Worksheets identical' if versions match
##############################################################################

compare_worksheets(newfile)

##############################################################################
# 2. Quality control - some general error checks
##############################################################################

# load data from excel workbook
wb = loadWorkbook(newfile)
ws = readWorksheet(wb, sheet = 1, header = TRUE, colTypes = XLC$DATA_TYPE.STRING)

rodent_data_quality_checks(ws, scannerfile)

##############################################################################
# 3. Correct recaptures - compare new data to older data
##############################################################################

# Load current state of database - older data
olddat = read.csv('./Rodents/Portal_rodent.csv', na.strings = '', as.is = T)

# Subset of most recent four years of data, for comparing recaptures
recentdat = olddat[olddat$year >= as.numeric(ws$year[1]) - 3,]

# check for missing * on new captures: looks for tags not already in database
#    -all entries in following results should have * in note2
#    -if it does not, check to see if animal was tagged day1 and then recaptured day2
#    -when making changes, add * to excel file of new data and note in book
newcaps = ws[!(ws$tag %in% unique(recentdat$tag)), c('plot','species','sex','tag','note2','note5')]
newcaps

# check to see if * put on note2 by accident: compare entries with * to list of tags not already in database
hasstar = ws[!is.na(ws$note2), c('plot','species','sex','tag','note2','note5')]
setdiff(hasstar$tag, newcaps$tag)

# Check sex/species on recaptures
#    -conflicts can be resolved if there's a clear majority, or if clear sexual characteristics
#    -also look back in book to see if sex/species data was manually changed before for a particular tag number
#    -when making changes to old or new data, note in book
sqldf("SELECT recentdat.period, recentdat.note1, recentdat.plot, ws.plot, recentdat.species, ws.species, recentdat.sex, ws.sex, recentdat.tag
       FROM recentdat INNER JOIN ws ON recentdat.tag = ws.tag
       WHERE (((recentdat.species)<>(ws.species)) And ((recentdat.tag)=(ws.tag))) Or (((recentdat.sex)<>(ws.sex)));")


##############################################################################
# 4. Append new data
##############################################################################

# make column of record IDs for new data
newdat = cbind(recordID = seq(max(olddat$recordID) + 1, max(olddat$recordID) + length(ws$month)), ws)
# append to existing data file
write.table(newdat, "./Rodents/Portal_rodent.csv", row.names = F, na = "", append=T, sep=",", col.names = F, quote = c(9,10,11,12,13,14,15,16,17,20,21,22,23,24,25,26,27,28,29))

##############################################################################
# 5. Update trapping records and new moon records
##############################################################################

### Update Trapping Records

# load rodent trapping data
trappingdat = read.csv("./Rodents/Portal_rodent_trapping.csv", stringsAsFactors = F)  

# proceed only if rodentdat has more recent data than trappingdat
if (max(newdat$period) > max(trappingdat$period)) {
  
  # convert newdat columns to integer
  newdat[,2:7] <- apply(newdat[,2:7], 2, function(x) as.integer(x))
  # extract plot data beyond what's already in trappingdat
  newtrapdat = filter(newdat, period > max(trappingdat$period)) %>%
    filter(!is.na(plot)) %>% 
    select(month, day, year, period, plot, note1)
  newtrapdat$sampled = rep(1)
  newtrapdat$sampled[newtrapdat$note1 == 4] = 0
  
  # select unique rows and rearrange columns
  newtrapdat = newtrapdat[!duplicated(select(newtrapdat, period, plot)), ] %>%
    select(day, month, year, period, plot, sampled)
  # put in order of period, plot
  newtrapdat = newtrapdat[order(newtrapdat$period, newtrapdat$plot), ]
  # rename columns
  names(newtrapdat) = c('day', 'month', 'year', 'period', 'plot', 'sampled')
  # write updated data frame to csv
  write.table(newtrapdat, "./Rodents/Portal_rodent_trapping.csv", row.names = F, col.names = F, append = T, sep = ",", quote = F)
  
}

### Update New Moon Records

# load existing moon_dates.csv file
moon_dates = read.csv("./Rodents/moon_dates.csv", stringsAsFactors = F)

# put date columns in appropriate date format
moon_dates$censusdate = as.Date(moon_dates$censusdate, format = '%Y-%m-%d')
moon_dates$newmoondate = as.Date(moon_dates$newmoondate, format = '%Y-%m-%d')
updated_trappingdat$censusdate = as.Date(paste(updated_trappingdat$year,
                                               updated_trappingdat$month,
                                               updated_trappingdat$day, sep = '-'))

# proceed only if trappingdat has more recent trapping data than moon_dates
if (max(updated_trappingdat$period, na.rm = T) > max(moon_dates$period, na.rm = T)) {
  
  # extract trappingdat periods beyond those included in moon_dates
  newperiods = filter(updated_trappingdat, period > max(moon_dates$period, na.rm = T))
  # reduce new trapping data to two columns: Period and CensusDate
  newperiods_dates = find_first_trap_night(newperiods)
  
  # match each new period to closest NewMoonDate, and fill in moon_dates data frame
  for (p in unique(newperiods_dates$period)) {
    closest = closest_newmoon(as.Date(newperiods_dates$censusdate[newperiods_dates$period == p]), 
                              as.Date(moon_dates$newmoondate))
    moon_dates$period[closest] = p
    moon_dates$censusdate[closest] = newperiods_dates$censusdate[newperiods_dates$period == p]
  }
  
  # write updated data frame to csv
  write.csv(moon_dates, file = './Rodents/moon_dates.csv', row.names = F)
  
}
