

# This script takes data that has already been entered twice and checked for typos, and does a few 
# data accuracy checks

# Note: name of excel file should be changed in line 10 of this script

rm(list=ls(all=TRUE))

period = '445'

library(XLConnect)

# ===========================================================================================
# functions 

find_pittags = function(ws1) {
  # this function extracts pit tags from the excel worksheet of new data
  sub1 = subset(ws1,!is.na(tag))
  pittags = sub1$tag
  return(pittags)
}

male_female_check = function(ws1) {
  # this function finds discrepancies between male/female specification and sexual traits
  issues = vector()
  for (n in 1:length(ws1$sex)) {
    if (ws1$sex[n] == 'F'){
      if (!is.na(ws1$testes[n])) {
        issues = append(issues,n+1)
      }
    }
    else {if (ws1$sex[n] == 'M'){
      if (!is.na(ws1$vagina[n]) || !is.na(ws1$pregnant[n]) || !is.na(ws1$nipples[n]) || !is.na(ws1$lactation[n])){
        issues = append(issues,n+1)
      }
    }
    }}
  return(issues)
}

suspect_stake = function(ws1) {
  # this function looks for duplicate plot-stake pairs to be labeled as suspect stake
  plotstake = paste(ws1$plot,ws1$stake)
  dups = plotstake[duplicated(plotstake)]
  return(dups)
}

# ===========================================================================================
# load data files

newfile = paste("C:/Users/ellen.bledsoe/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/newdat",
                period,'.xlsx',sep='')

scannerfile = paste("C:/Users/ellen.bledsoe/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/tag scans/tags",
                    period,'.txt',sep='')

wb = loadWorkbook(newfile)
ws1 = readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)

# ===========================================================================================
# compare pit tags in excel file to scanner download data

scandat = read.table(scannerfile,header=FALSE,sep='.',blank.lines.skip=TRUE,
                     col.names=c('v1','tag','date','time'))
scans = vector()
for (tag in as.vector(scandat$tag)) {
  scans = append(scans,substr(tag,5,10))
}

pittags = find_pittags(ws1)

# ===========================================================================================
# check for M/F consistency in traits
issues = male_female_check(subset(ws1,!is.na(sex)))

# ===========================================================================================
# check for duplicate stakes in same plot
dups = suspect_stake(ws1)

# ===========================================================================================
# checks that all plots are represented in the data (even empty ones)
plots = unique(ws1$plot)
missingplots = setdiff(as.character(1:24),plots)

# ===========================================================================================
# print output

print(paste('in scans not sheets:',setdiff(scans,pittags)))
print(paste('in sheets not scans:',setdiff(pittags,scans)))
print(paste('check male/female in rows:',issues))
print(paste('suspect stakes (plot stake):',dups))
print(paste('missing plots:',missingplots))

