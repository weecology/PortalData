# This script is for cleaning new rodent data.  Data must first be entered in two separate sheets in
# an excel file, by two different people to reduce entry error.

library(XLConnect)
library(sqldf)

source('compare_raw_data.r')
source('compare_tags.r')
source('check_reproductive_status.r')
source('check_all_plots_present.r')
source('check_stake_duplicates.r')
source('check_missing_data.r')

##############################################################################
# New file to be checked
##############################################################################

newperiod = '456'
filepath = 'C:/Users/EC/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/'

newfile = paste(filepath, 'newdat', newperiod, '.xlsx', sep='')
scannerfile = paste(filepath, 'tag scans/tags', newperiod, '.txt', sep='')

##############################################################################
# 1. Compare double-entered data -- will return 'Worksheets identical' if versions match
##############################################################################

compare_worksheets(newfile)

##############################################################################
# 2. Quality control - some general error checks
##############################################################################

# load data from excel workbook
wb = loadWorkbook(newfile)
ws = readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)

# Compare tag numbers entered on sheets to scanner download
compare_tags(ws,scannerfile)

# Check that reproductive charactaristics match M/F designation
male_female_check(ws)

# Check all plots present in data
all_plots(ws)

# Check for duplicate stake numbers within a plot
suspect_stake(ws)

# Flag missing data
#   -fields all lines of data should have
check_missing_data(ws,fields = c('mo','dy','yr','period','plot'))
#   -fields that should be filled, excluding cases that already have a flag
#    in the note1 field
check_missing_data(ws[is.na(ws$note1),],fields=c('stake','species','sex','hfl','wgt'))
#   - NOTE: does not check for missing tag or sexual characteristics


##############################################################################
# 3. Correct recaptures - compare new data to older data
##############################################################################

# Load current state of database - older data
olddat = read.csv('../Rodents/Portal_rodent.csv',na.strings='',as.is=T)

# Subset of most recent four years of data, for comparing recaptures
recentdat = olddat[olddat$yr >= as.numeric(ws$yr[1])-3,]

# check for missing * on new captures: looks for tags not already in database
#    -all entries in following results should have * in note2
#    -if it does not, check to see if animal was tagged day1 and then recaptured day2
#    -when making changes, add * to excel file of new data and note in book
newcaps = ws[!(ws$tag %in% unique(recentdat$tag)),c('plot','species','sex','tag','note2','note5')]
newcaps

# check to see if * put on note2 by accident: compare entries with * to list of tags not already in database
hasstar = ws[!is.na(ws$note2),c('plot','species','sex','tag','note2','note5')]
setdiff(hasstar$tag,newcaps$tag)

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
newdat = cbind(Record_ID = seq(max(olddat$Record_ID)+1,max(olddat$Record_ID)+length(ws$mo)),ws)
# append to existing data file
write.table(newdat,"../Rodents/Portal_rodent.csv", row.names=F,na="",append=T, sep=",", col.names=F,quote=c(9,10,11,12,13,14,15,16,17,20,21,22,23,24,25,26,27,28,29))
