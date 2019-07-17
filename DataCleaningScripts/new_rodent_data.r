# This script is for cleaning new rodent data.  Data must first be entered in two separate sheets in
# an excel file, by two different people to reduce entry error.

library(openxlsx)
library(sqldf)
library(RCurl)
library(dplyr)

source('DataCleaningScripts/general_data_cleaning_functions.R')
source('DataCleaningScripts/rodent_data_cleaning_functions.R')


##############################################################################
# New file to be checked
##############################################################################

newperiod = '486'
filepath = '~/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/'

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

# check for unusual weight/hfl measurements by species

speciesnorms = read.csv('Rodents/Portal_rodent_species.csv', header = T, stringsAsFactors = F, na.strings = "")

speciesnorms = filter(speciesnorms, censustarget == 1) %>%
  filter(unidentified == 0) %>%
  select('speciescode')

colnames(speciesnorms) = c('species')

speciesnorms$wgt.min = NA
speciesnorms$wgt.max = NA
speciesnorms$hfl.min = NA
speciesnorms$hfl.max = NA


for (i in 1:nrow(speciesnorms)) {
  
  this.sp = filter(olddat, species == speciesnorms$species[i])
  this.sp = this.sp[ which(this.sp$note1 != 12 | is.na(this.sp$note1)), ]
  speciesnorms$wgt.min[i] = min(this.sp$wgt, na.rm = T)
  speciesnorms$wgt.max[i] = max(this.sp$wgt, na.rm = T)
  speciesnorms$hfl.min[i] = min(this.sp$hfl, na.rm = T)
  speciesnorms$hfl.max[i] = max(this.sp$hfl, na.rm = T)
  
}

records = left_join(ws, speciesnorms, by = 'species')
records = mutate(records, rownum = 1:nrow(records)) %>%
  mutate(record_measurement = ((wgt < wgt.min) | (wgt > wgt.max )| (hfl < hfl.min )| (hfl > hfl.max))) %>%
  filter(record_measurement == TRUE)

if (nrow(records) > 0) {
  for (i in 1:nrow(records)) {
    print("Record weight or hindfoot measurement:")
    print(records[i])
    change = readline(prompt="Type Y to edit ws or add note")
    if (change == "Y") {
      new.wgt = readline(prompt = "Change weight? (Type Y for yes)")
      if (new.wgt == "Y") {
        newval = readline(prompt = "New weight:")
        ws[records$rownum[i], 'wgt'] <- newval
      }
      
      new.hfl = readline(prompt = "Change hfl? (Type Y for yes)")
      
      if (new.hfl == "Y") {
        newval = readline(prompt = "New hfl:")
        ws[records$rownum[i], 'hfl'] <- newval
      }
      
      add.note = readline(prompt = "Add note1 = 12 for suspect wgt/hlf? (Type Y for yes)")
      if (add.note == "Y") {
        ws[records$rownum[i], 'note1'] <- 12
      }
    }
    
  }
  
}

rm(records)
rm(speciesnorms)
rm(this.sp)

# check for missing * on new captures: looks for tags not already in database
#    -all entries in following results should have * in note2
#    -if it does not, check to see if animal was tagged day1 and then recaptured day2
#    -when making changes, add * to excel file of new data and note in book
newcaps = ws[!(ws$tag %in% unique(olddat$tag)), c('plot','species','sex','tag','note2','note5')]

newcaps


# Look for individuals captured twice in a census
double_caps = ws %>%
  filter(!is.na(tag)) %>%
  select(tag) %>%
  group_by(tag) %>%
  tally() %>%
  filter(n > 1) 

if (anyNA(newcaps$note2)) {
  nostar = newcaps[ which(is.na(newcaps$note2)), ]
  for (i in 1:nrow(nostar)) {
    if(nostar[i, 'tag'] %in% double_caps$tag) {
      all_caps = ws[ which(ws$tag == nostar[i, 'tag']), ]
      if(any(!is.na(all_caps$note2))) {
        next
      } else {
        print("Captured twice this census and missing star for both.")
        print("Type Y to add star to first record for this individidual in this census")
        add.star = readline()
        if(add.star == 'Y') {
          ws[min(row.names(all_caps)), 'note2'] <- '*'
          print( ws[min(row.names(all_caps)), ])
          print('Remember to record on datasheet + in notebook!')
          next
        }
      }
    }
    print(nostar[which(nostar$tag == nostar$tag[[i]]), ])
    print("Type Y to add star in worksheet")
    add.star = readline()
    if(add.star == 'Y') {
      ## To add a star:
      ws[row.names(nostar)[i], 'note2'] <- '*'
      print(ws[row.names(nostar)[i], ])
      print('Remember to record on datasheet + in notebook!')
    }
    readline(prompt="Press [enter] to continue")
  }
  print('No more missing stars')
  rm(nostar)
  
}


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
      print(thisone[,c('period', 'plot', 'species', 'sex', 'reprod', 'age', 'testes', 'vagina', 'pregnant', 'nipples', 'lactation','tag')])
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

# Check to see if you can fill in species of sex data from previous records
#   - will also allow you to change note1 to 16
#   - only do this if no other data are missing (e.g. hfl, wgt)


missingdat_PIT <-ws[!is.na(ws$tag) & (is.na(ws$sex) | is.na(ws$species)),
                    c("period", "plot", "species", "sex", "tag")]

tags = (unique(missingdat_PIT$tag))

if (length(tags) > 0) {
  for (i in 1:length(tags)) {
    thisone.old = olddat[which(olddat$tag == tags[i]), 2:29]
    thisone.new = ws[which(ws$tag == tags[i]),]
    thisone = rbind(thisone.old, thisone.new)
    
    if (nrow(thisone) > 1) {
      print('Missing data can be filled:')
      print(thisone[, c('period', 'plot', 'note1', 'species', 'sex', 'tag')])
      print('Edit a record? (Y/N)')
      edit = readline()
      
      if (edit == "Y") {
        print("Row number?")
        row.id = as.integer(readline())
        print('Edit species? (Y/N)')
        sp_edit = readline()
        
        if (sp_edit == 'Y') {
          print('New species code?')
          sp.code = readline()
          ws[row.id, 'species'] <- sp.code
          print(ws[row.id,])
        } else {
          print('Not editing species')
        }
        
        print('Edit sex? (Y/N)')
        sex_edit = readline()
        
        if (sex_edit == 'Y') {
          print('New sex?')
          sex.code = readline()
          ws[row.id, 'sex'] <- sex.code
          print(ws[row.id,])
        } else {
          print('Not editing sex')
        }
        
        print('Change note1 to 16 (only if no other missing data)? (Y/N)')
        note1_edit = readline()
        
        if (note1_edit == 'Y') {
          ws[row.id, 'note1'] <- 16
        } else {
          print('Not editing note1')
        }
        
        readline(prompt = "Press [enter] to continue")
        print('Remember to record in notebook/on datasheet!')
        readline(prompt = "Press [enter] to continue")
        
      }
      
      if (edit != 'Y') {
        print('Not editing')
        readline(prompt = "Press [enter] to continue")
        
      }
      
    }
    
  }
  print('No more edits to make')
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
