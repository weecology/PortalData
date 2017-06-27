# This script creates the Portal_rodent_trapping.csv file in the Rodents folder
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
  rodentdat = read.csv("../Rodents/Portal_rodent.csv",stringsAsFactors = F,as.is=T,na.strings = '')  
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
#' @example writetrappingtable(trappingdat)
#' 
#'
#'
writetrappingtable <- function(trappingdat) {
  # write updated data frame to csv
  write.csv(updated_trappingdat,file=final_data_location,row.names=F) }

#################################################################################################################################################
# This is how Portal_rodent_trapping.csv was originally created
#' Creates file Portal_rodent_trapping.csv from scratch, using the most current version of Portal_rodent.csv
#'
#'
#'
#' @param final_data_location file path where csv of final data should be saved (in the PortalData repo) 
#' 
#' @example create_portal_rodent_trapping('C:/Users/EC/Desktop/git/PortalData/Rodents/Portal_rodent_trapping.csv')
#' 
#' 

create_portal_rodent_trapping = function(final_data_location) {
  # load rodent data
  rodentdat = read.csv(text=getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Rodents/Portal_rodent.csv"),stringsAsFactors = F,as.is=T,na.strings = '')  
  
  # remove rows not belonging to regular census; select date, period, plot columns
  plotdat = rodentdat %>% filter(period > 0, !is.na(plot)) %>% select(mo,dy,yr,period,plot,note1)
  
  # make column for sampled/not sampled
  plotdat$Sampled = rep(1)
  plotdat$Sampled[plotdat$note1 == 4] = 0
  
  # create final data frame
  portal_trapping = data.frame(Day = plotdat$dy,
                               Month = plotdat$mo,
                               Year = plotdat$yr,
                               Period = plotdat$period,
                               Plot = plotdat$plot,
                               Sampled = plotdat$Sampled)
  
  # remove duplicate rows
  portal_trapping = portal_trapping[!duplicated(portal_trapping[,c(4,5,6)]),]
  
  # checks for periods with less than 24 plots
  check = aggregate(portal_trapping$Sampled,by=list(portal_trapping$Period),FUN = length)
  #check[check$x != 24,]
  
  # fill in missing plots with "not trapped"; take a date from date plot1 was trapped in that period
  short = check$Group.1[check$x<24]
  for (n in short) {
    period = portal_trapping[portal_trapping$Period == n,]
    for (plt in seq(24)) {
      if (!(plt %in% period$Plot)) {
        portal_trapping = rbind(portal_trapping,c(period$Day[1],period$Month[1],period$Year[1],period$Period[1],plt,0))
      }
    }
  }
  
  # put in order of period, plot
  portal_trapping = portal_trapping[order(portal_trapping$Period,portal_trapping$Plot),]
  
  # write to file
  write.csv(portal_trapping,file=final_data_location, row.names = F)
}



