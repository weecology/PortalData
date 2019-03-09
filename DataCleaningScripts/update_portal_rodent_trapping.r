# This creates the Portal_rodent_trapping.csv file in the Rodents folder
# Record of which plots were or were not trapped in each census and exact dates

library(dplyr)
library(zoo)

#' Appends new trapping dates to Portal_rodent_trapping
#'
#'
#' 
#' @example update_portal_rodent_trapping()
#' 
#'
#'

update_portal_rodent_trapping = function() {
  # load rodent data
  rodentdat = read.csv("Rodents/Portal_rodent.csv",stringsAsFactors = FALSE,as.is=TRUE,na.strings = '')  
  # load rodent trapping data
  trappingdat=read.csv("Rodents/Portal_rodent_trapping.csv")  
  
  # proceed only if rodentdat has more recent data than trappingdat
  if (max(abs(rodentdat$period)) > max(abs(trappingdat$period))) {
    
    # extract plot data beyond what's already in trappingdat
    newdat = filter(rodentdat,period > max(trappingdat$period)) %>% filter(!is.na(plot)) %>% select(month,day,year,period,plot,note1)
    newdat$sampled = rep(1)
    newdat$effort = rep(49)
    newdat$sampled[newdat$note1==4] = 0
    newdat$effort[newdat$note1==4] = 0
    newdat$qcflag = 0
    # select unique rows and rearrange columns
    newdat = newdat[!duplicated(select(newdat,period,plot)),] %>% select(day,month,year,period,plot,sampled,effort,qcflag)
    # put in order of period, plot
    newdat = newdat[order(newdat$period,newdat$plot),]
    # append to trappingdat
    trappingdat = rbind(trappingdat,newdat)
    
    dates = as.yearmon(paste(trappingdat$month,"/",trappingdat$year,sep=""), "%m/%Y")
    trappingdat$qcflag[dates<as.yearmon(Sys.Date())-1] = 1
  }
  return(trappingdat)
}

#' Rewrites file Portal_rodent_trapping.csv with latest trapping dates
#'
#'
#' 
#' @example writetrappingtable()
#' 
#'
#'
writetrappingtable <- function() {
  
  trappingdat=update_portal_rodent_trapping()
  # write updated data frame to csv
  write.csv(trappingdat, file="Rodents/Portal_rodent_trapping.csv", row.names=FALSE, quote = FALSE) }
