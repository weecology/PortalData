# This creates the Portal_rodent_trapping.csv file in the Rodents folder
# Record of which plots were or were not trapped in each census and exact dates

library(dplyr)

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
  rodentdat = read.csv("../Rodents/Portal_rodent.csv",stringsAsFactors = FALSE,as.is=TRUE,na.strings = '')  
  # load rodent trapping data
  trappingdat=read.csv("../Rodents/Portal_rodent_trapping.csv")  
  
  # proceed only if rodentdat has more recent data than trappingdat
  if (max(abs(rodentdat$period)) > max(abs(trappingdat$Period))) {
    
    # extract plot data beyond what's already in trappingdat
    newdat = filter(rodentdat,period > max(trappingdat$Period)) %>% filter(!is.na(plot)) %>% select(mo,dy,yr,period,plot,note1)
    newdat$Sampled = rep(1)
    newdat$Sampled[newdat$note1==4] = 0
    # select unique rows and rearrange columns
    newdat = newdat[!duplicated(select(newdat,period,plot)),] %>% select(dy,mo,yr,period,plot,Sampled)
    # put in order of period, plot
    newdat = newdat[order(newdat$period,newdat$plot),]
    #rename columns
    colnames(newdat) = c("Day","Month","Year","Period","Plot","Sampled")
    # append to trappingdat
    trappingdat = rbind(trappingdat,newdat)
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
  write.csv(trappingdat, file="../Rodents/Portal_rodent_trapping.csv", row.names=FALSE, quote = FALSE) }
