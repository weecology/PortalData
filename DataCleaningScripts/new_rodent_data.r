# This script is for cleaning new rodent data.  Data must first be entered in two separate sheets in
# an excel file, by two different people to reduce entry error.

library(openxlsx)
library(sqldf)
library(RCurl)
library(dplyr)
# setwd("~/Users/renatadiaz/Documents/GitHub/PortalData")

source('DataCleaningScripts/compare_raw_data.r')
source('DataCleaningScripts/rodent_data_cleaning_functions.R')


# set your working directory

##############################################################################
# New file to be checked
##############################################################################

newperiod = '465'
filepath = '/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/'

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
ws = read.xlsx(newfile, sheet = 1, colNames = TRUE, na.strings = '')

rodent_data_quality_checks(ws, scannerfile)

##############################################################################
# 3. Correct recaptures - compare new data to older data
##############################################################################

# Load current state of database - older data
olddat = read.csv('Rodents/Portal_rodent.csv', na.strings = '', as.is = T)

# Subset of most recent four years of data, for comparing recaptures
# recentdat = olddat[olddat$year >= as.numeric(ws$year[1]) - 3,]

# check for missing * on new captures: looks for tags not already in database
#    -all entries in following results should have * in note2
#    -if it does not, check to see if animal was tagged day1 and then recaptured day2
#    -when making changes, add * to excel file of new data and note in book
newcaps = ws[!(ws$tag %in% unique(olddat$tag)), c('plot','species','sex','tag','note2','note5')]
newcaps

if (anyNA(newcaps$note2)) {
  nostar = filter(newcaps, is.na(note2))
  for (i in 1:nrow(nostar)) {
    print(nostar[i, ])
    print("Type Y to add star in worksheet")
    add.star = readline()
    if(add.star == 'Y') {
      ## To add a star: 
      ws[which(ws$tag == nostar[i, 'tag']), 'note2'] <- '*'
      print(ws[which(ws$tag == nostar[i, 'tag']), ])
      print('Remember to record on datasheet + in notebook!')
    }
    readline(prompt="Press [enter] to continue")
  }
  print('No more missing stars')
}

rm(nostar)

# check to see if * put on note2 by accident: compare entries with * to list of tags not already in database
hasstar = ws[!is.na(ws$note2), c('plot','species','sex','tag','note2','note5')]

extrastar = hasstar[which(hasstar$tag %in% setdiff(hasstar$tag, newcaps$tag)), ]

if (nrow(extrastar) > 0) {
  for (i in 1:nrow(extrastar)) {
    print(extrastar[i, ])
    print("Type Y to remove star in worksheet")
    remove.star = readline()
    if(remove.star == 'Y') {
      ## To remove a star: 
      ws[which(ws$tag == extrastar[i, 'tag']), 'note2'] <- NA
      print(ws[which(ws$tag == extrastar[i, 'tag']), ])
      print('Remember to record on datasheet + in notebook!')
    }
    readline(prompt="Press [enter] to continue")
  }
  print('No more extra stars')
}

rm(hasstar)
rm(extrastar)
rm(newcaps)

# Check sex/species on recaptures
#    -conflicts can be resolved if there's a clear majority, or if clear sexual characteristics
#    -also look back in book to see if sex/species data was manually changed before for a particular tag number
#    -when making changes to old or new data, note in book

# introducing a sex error and a species error

head(ws)

ws[3, 'species'] <- 'XX'
ws[4, 'sex'] <- 'J'

sexmismatch  = sqldf("SELECT olddat.period, olddat.note1, olddat.plot, ws.plot, olddat.species, ws.species, olddat.sex, ws.sex, olddat.tag
       FROM olddat INNER JOIN ws ON olddat.tag = ws.tag
       WHERE (((olddat.species)<>(ws.species)) And ((olddat.tag)=(ws.tag))) Or (((olddat.sex)<>(ws.sex)));")

tags = (unique(sexmismatch$tag))
if (length(tags) > 0) {
  for(i in 1:length(tags)) {
    print("Mismatch tag:")
    print(tags[i])
    thisone.old = olddat[ which(olddat$tag == tags[i]), 2:29]
    thisone.new = ws[ which(ws$tag == tags[i]), ]
    thisone = rbind(thisone.old, thisone.new)
    # print('Old record(s):')
    # print(thisone.old)
    # print('New record(s):')
    # print(thisone.new)
    if(length(unique(thisone$species)) >1) {
      print('Species mismatch:')
      print(thisone[,c('period', 'plot', 'species', 'tag')])
      print('Edit a record?')
      edit = readline()
      if (edit == "Y") {
        print("Row number?")
        row.id = as.integer(readline())
        print('New species code?')
        sp.code = readline()
        
        if (row.id %in% row.names(thisone.old)) {
          olddat[row.id, 'species'] <- sp.code
          print(olddat[row.id, ])
        }
        if (row.id %in% row.names(ws)) {
          ws[row.id, 'species'] <- sp.code
          print(ws[row.id, ])
        }
      }
      
      if (edit != 'Y') {
        print('Not editing')
      }
      
      print('Remember to record in notebook/on datasheet!')
      
      readline(prompt="Press [enter] to continue")
    }
    
    if (length(unique(thisone$sex)) > 1) {
      print('Sex mismatch:')
      print(thisone[,c('period', 'plot', 'species', 'sex', 'tag')])
      print('Edit a record?')
      edit = readline()
      if (edit == "Y") {
        print("Row number?")
        row.id = as.integer(readline())
        print('New sex?')
        new.sex = readline()
        
        if (row.id %in% row.names(thisone.old)) {
          olddat[row.id, 'sex'] <- new.sex
          print(olddat[row.id, ])
        }
        if (row.id %in% row.names(ws)) {
          ws[row.id, 'sex'] <- new.sex
          print(ws[row.id, ])
        }
      }
      
      if (edit != 'Y') {
        print('Not editing')
      }
      
      print('Remember to record in notebook/on datasheet!')
      
      readline(prompt="Press [enter] to continue")
    }
    
    # print updated version of records
    print('Updated records:')
    print(olddat[which(olddat$tag == tags[i]), 2:29])
    print(ws[ which(ws$tag == tags[i]), ])
    readline(prompt="Press [enter] to continue")
    
  }
  print('No more mismatches')
}


##############################################################################
# 4. Append new data
##############################################################################

# make column of record IDs for new data
newdat = cbind(recordID = seq(max(olddat$recordID) + 1, max(olddat$recordID) + length(ws$month)), ws)

# append to existing data file
#write.table(newdat, "./Rodents/Portal_rodent.csv", row.names = F, na = "", append=T, sep=",", col.names = F, quote = c(9,10,11,12,13,14,15,16,17,20,21,22,23,24,25,26,27,28,29))

# resave updated data file
correcteddat = rbind(olddat, newdat)

write.table(correcteddat, "./Rodents/Portal_rodent.csv", row.names = F, na = "", append=F, sep=",", col.names = T, quote = c(9,10,11,12,13,14,15,16,17,20,21,22,23,24,25,26,27,28,29))

##############################################################################
# 5. Update trapping records and new moon records
##############################################################################
# 
# ### Update Trapping Records
# 
# # load rodent trapping data
# trappingdat = read.csv("./Rodents/Portal_rodent_trapping.csv", stringsAsFactors = F)  
# 
# # proceed only if rodentdat has more recent data than trappingdat
# if (max(newdat$period) > max(trappingdat$period)) {
#   
#   # convert newdat columns to integer
#   newdat[,2:7] <- apply(newdat[,2:7], 2, function(x) as.integer(x))
#   # extract plot data beyond what's already in trappingdat
#   newtrapdat = filter(newdat, period > max(trappingdat$period)) %>%
#     filter(!is.na(plot)) %>% 
#     select(month, day, year, period, plot, note1)
#   newtrapdat$sampled = rep(1)
#   newtrapdat$sampled[newtrapdat$note1 == 4] = 0
#   
#   # select unique rows and rearrange columns
#   newtrapdat = newtrapdat[!duplicated(select(newtrapdat, period, plot)), ] %>%
#     select(day, month, year, period, plot, sampled)
#   # put in order of period, plot
#   newtrapdat = newtrapdat[order(newtrapdat$period, newtrapdat$plot), ]
#   # rename columns
#   names(newtrapdat) = c('day', 'month', 'year', 'period', 'plot', 'sampled')
#   # write updated data frame to csv
#   write.table(newtrapdat, "./Rodents/Portal_rodent_trapping.csv", row.names = F, col.names = F, append = T, sep = ",", quote = F)
#   
# }
# 
# ### Update New Moon Records
# source('./DataCleaningScripts/new_moon_numbers.r')
# writenewmoons()

