# some code to match new moon dates to period sampling dates
# new moon dates downloaded from http://www.somacon.com/p570.php
#   --data from this site is a csv with columns: date, time, phase, phaseid, datetime, timestamp, friendlydate

library(dplyr)


#' Find date of first trapping night for each period in a data frame
#' Returns data frame of Period (unique period numbers) and CensusDate
#'
#'
#'
#' @param dat data frame containing at least columns "Period" and "CensusDate"
#' 
#' @example find_first_trap_night(trappingdat)
#' 
find_first_trap_night = function(dat) {
  trap_dates = c()
  for (p in unique(dat$Period)) {
    perioddate <- dat %>% filter(Period==p) %>% filter(CensusDate == min(CensusDate)) %>% head(1) %>% select(Period,CensusDate)
    trap_dates = rbind(trap_dates,perioddate)
  }
  return(trap_dates)
}


#' Finds the date in a vector of dates (new moons) that is closest to a target date (a census)
#' Returns the index of the vector
#'
#'
#' @param target_date single date object
#' @param newmoondates vector of date objects
#' 
#' @example closest_newmoon(as.Date('2017-02-26'),moon_dates$NewMoonDate)
#' 
closest_newmoon = function(target_date,newmoondates) {
  closest = which.min(abs(target_date-newmoondates))
  return(closest)
}

#' Updates existing version of moon_dates.csv with latest census numbers
#'
#'
#'
#' @param
#' 
#' @example update_moon_dates()

update_moon_dates = function() {
  # load existing moon_dates.csv file
  moon_dates=read.csv("../Rodents/moon_dates.csv",stringsAsFactors = F)
  moon_dates$NewMoonDate = as.Date(moon_dates$NewMoonDate)
  moon_dates$CensusDate = as.Date(moon_dates$CensusDate)
  # load rodent trapping data
  trappingdat=read.csv("../Rodents/Portal_rodent_trapping.csv")  
  trappingdat$CensusDate = as.Date(paste(trappingdat$Year,trappingdat$Month,trappingdat$Day,sep='-'))
  # load new moon dates
  newmoons=read.csv(url('https://www.dropbox.com/s/z9kq7qvu2r7uwzu/moon-phases-1977-2018-America_Phoenix.csv?dl=1'),header = T, stringsAsFactors = F) %>%
    filter(phaseid==1) 
  newmoons$date = as.Date(newmoons$date, format='%m/%d/%Y') 
  #keep only newmoons past those currently assigned a newmoonnumber
  newmoons=filter(newmoons,date>tail(moon_dates$NewMoonDate,n=1))
  #add newmoonnumbers to newmoondates
  newmoons$NewMoonNumber=tail(moon_dates$NewMoonNumber,n=1)+1:dim(newmoons)[1]
  
  # proceed only if trappingdat has more recent dates than moon_dates
  if (max(abs(trappingdat$Period),na.rm=T) > max(abs(moon_dates$Period),na.rm=T)) {
    
    # extract trappingdat periods beyond those included in moon_dates
    newperiod = filter(trappingdat,abs(Period)>max(abs(moon_dates$Period),na.rm=T))
    # reduce new trapping data to two columns: Period and CensusDate
    newperiod_dates = find_first_trap_night(newperiod)

    # match new period to closest NewMoonDate, and fill in moon_dates data frame
      closest = closest_newmoon(as.Date(newperiod_dates$CensusDate),as.Date(newmoons$date))
      newmoons=newmoons[1:closest,]
      moon_dates=bind_rows(moon_dates,select(newmoons,c(NewMoonNumber,NewMoonDate=date)))
      
      tail(moon_dates$Period,n=1) = unique(newperiod)
      tail(moon_dates$CensusDate,n=1) = unique(newperiod_dates$CensusDate)
  }
  return(moon_dates)
}


# write updated data frame to csv

writenewmoons <- function(moon_dates) {
write.csv(moon_dates,file="../Rodents/moon_dates.csv",row.names=F) }

#############################################################################################################################################

#' This is how the original file moon_dates.csv was created from scratch
#'
#'
#'
#' @param moon_data_location file path of downloaded moon phase data
#' @param final_data_location file path where csv of final data should be saved (in the PortalData repo)
#' 
#' @example create_moon_dates(moon_data_location='C:/Users/EC/Dropbox/Portal/PORTAL_primary_data/Rodent/Documents/moon-phases-1977-2018-America_Phoenix.csv',
#'                            final_data_location='C:/Users/EC/Desktop/git/PortalData/Rodents/moon_dates.csv')


create_moon_dates = function(moon_data_location,final_data_location) {
  # download current version of file containing rodent census periods and dates
  trappingdat=read.csv(text=getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Rodents/Portal_rodent_trapping.csv"))  
  trappingdat$CensusDate = as.Date(paste(trappingdat$Year,trappingdat$Month,trappingdat$Day,sep='-'))
  
  # Create data frame of period numbers and date of first trapping night
  census_dates = find_first_trap_night(trappingdat)
  
  # read file of moon data
  moondat = read.csv(moon_data_location, stringsAsFactors = F)
  # date in format R understands
  moondat$NewMoonDate = as.Date(moondat$date, format='%m/%d/%Y')
  # extract new moons; make sure data starts no earlier than 7/16/1977
  newmoon = filter(moondat, phaseid==1, NewMoonDate>=as.Date('1977-07-15')) %>% select(NewMoonDate)
  # create index of number of new moons since july 1977
  newmoon$NewMoonNumber = seq(1,length(newmoon$NewMoonDate))
  
  # loop through CensusDate and match each to closest NewMoonDate
  newmoon$Period = rep(NA)
  for (ind in seq(length(census_dates$CensusDate))) {
    closest = which.min(abs(census_dates$CensusDate[ind]-newmoon$NewMoonDate))
    newmoon$Period[closest] = census_dates$Period[ind]
  }
  
  # merge into one big data frame
  moon_dates = merge(newmoon,census_dates,all.x=T,by=('Period')) %>% arrange(NewMoonDate) %>% select(NewMoonNumber,NewMoonDate, Period, CensusDate)
  
  # awkward patch for Feb 1994: period 191 (1994-02-01) and 192 (1994-02-20) share new moon 206 (1994-02-10) as the closest new moon,
  #    but new moon 205 (1994-01-11) has no associated trapping period--> match up period 191 and newmoon 205
  moon_dates[moon_dates$NewMoonNumber==205,'Period'] = 191
  moon_dates[moon_dates$NewMoonNumber==205,'CensusDate'] = as.Date('1994-02-01')
  
  # write to csv
  write.csv(moon_dates,file=final_data_location,row.names=F)
}



