library(dplyr)

source('check_all_plots_present.r')
source('check_missing_data.r')

#' Main function: runs a few rodent data quality checks
#' 
#'
#' @param ws data frame read in from raw data excel file
#' @param scannerfile path to txt file of tag numbers downloaded from tag scanner
#' 
#' @return none

rodent_data_quality_checks = function(ws,scannerfile) {
  
  # Compare tag numbers entered on sheets to scanner download
  unpaired = compare_tags(ws,scannerfile)
  if (nrow(unpaired) > 0) {
    print('tag number problem:')
    print(unpaired)
  }
  
  # Check that reproductive charactaristics match M/F designation
  MFcheck = male_female_check(ws)
  if (nrow(MFcheck) > 0) {
    print('check M/F in rows:')
    print(row.names(MFcheck))
  }
  
  # Check for duplicate stake numbers within a plot
  dups = suspect_stake(ws)
  if (nrow(dups) > 0) {
    print('suspect stakes:')
    print(dups)
  }
  
  # Check all plots present in data
  all_plots(ws)
  
  # Flag missing data
  #   -fields all lines of data should have
  check_missing_data(ws,fields = c('mo','dy','yr','period','plot'))
  #   -fields that should be filled, excluding cases that already have a flag
  #    in the note1 field
  check_missing_data(ws[is.na(ws$note1),],fields=c('stake','species','sex','hfl','wgt'))
  #   - NOTE: does not check for missing tag or sexual characteristics
  
}








#' This function compares pit tags entered on data sheets to tags downloaded from scanner
#' 
#' @param ws data frame read in from raw data excel file
#' @param scannerfile path to txt file of tag numbers downloaded from tag scanner
#' 
#' @return unpaired -- data frame with columns where and tag
#'                   where = where tag is found, data sheet or scanner file
#'                   tag = tag number

compare_tags = function(ws,scannerfile) {
  
  # extract tag numbers from raw data
  sheets = subset(ws$tag,!is.na(ws$tag))
  
  # load data from scanner
  scandat = read.table(scannerfile, 
                       header=FALSE, 
                       sep='.', 
                       blank.lines.skip=TRUE,
                       col.names=c('v1','tag','date','time'))
  
  # extract 6-digit tag numbers from scanner
  scans = vector()
  for (tag in as.vector(scandat$tag)) {
    scans = append(scans,substr(tag,5,10))
  }
  
  scannotsheet = setdiff(scans,sheets)
  sheetnotscan = setdiff(sheets,scans)
  unpaired = data.frame(where=c(rep('scan',length(scannotsheet)),rep('sheet',length(sheetnotscan))),
                        tag=c(scannotsheet,sheetnotscan))
  
  return(unpaired)
}


#' Checks for conflict between reproductive characteristics and M/F designation in raw entered rodent data
#' 
#'
#' @param ws data frame read in from raw data excel file
#' 
#' @return MFcheck -- a data frame of the rows from the original data where there is a problem
#'
male_female_check = function(ws) {
  
  # remove entries with missing M/F designation from error check
  ws1 = subset(ws,!is.na(sex))
  
  issues = vector()
  for (n in 1:length(ws1$sex)) {
    if (ws1$sex[n] == 'F'){
      if (!is.na(ws1$testes[n])) {
        issues = append(issues,n+1)
      }
    }
    else {if (ws1$sex[n] == 'M'){
      if (!is.na(ws1$vagina[n]) || !is.na(ws1$pregnant[n]) || !is.na(ws1$nipples[n]) || !is.na(ws1$lactation[n])){
        issues = append(issues,row.names(ws1)[n+1])
      }
    }
    }}
  MFcheck = filter(ws1,row.names(ws1) %in% issues)
  return(MFcheck)
}


#' Looks for duplicate stake numbers within a plot (rodent data) that should be labeled as suspect stake
#' 
#' @param ws data frame read in from raw data excel file
#' 
#' @return dups data frame of duplicated plot and stake
#' 


suspect_stake = function(ws) {
  plotstake = select(ws,plot,stake)
  dups = filter(plotstake,duplicated(plotstake))
  return(dups)
}

