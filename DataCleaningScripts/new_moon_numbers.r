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
#' 
#' @example update_moon_dates()

update_moon_dates = function() {
  # load existing moon_dates.csv file
  moon_dates=read.csv("../Rodents/moon_dates.csv",stringsAsFactors = FALSE)
  moon_dates$NewMoonDate = as.Date(moon_dates$NewMoonDate)
  moon_dates$CensusDate = as.Date(moon_dates$CensusDate)
  # load rodent trapping data
  trappingdat=read.csv("../Rodents/Portal_rodent_trapping.csv")  
  trappingdat$CensusDate = as.Date(paste(trappingdat$Year,trappingdat$Month,trappingdat$Day,sep='-'))
  # load new moon dates
  newmoons=read.csv(url('https://www.dropbox.com/s/z9kq7qvu2r7uwzu/moon-phases-1977-2018-America_Phoenix.csv?dl=1'),header = TRUE, stringsAsFactors = FALSE) %>%
    filter(phaseid==1) 
  newmoons$date = as.Date(newmoons$date, format='%m/%d/%Y') 
  #keep only newmoons past those currently assigned a newmoonnumber
  newmoons=filter(newmoons,date>tail(moon_dates$NewMoonDate,n=1))
  #add newmoonnumbers to newmoondates
  newmoons$NewMoonNumber=tail(moon_dates$NewMoonNumber,n=1)+1:dim(newmoons)[1]
  
  # proceed only if trappingdat has more recent dates than moon_dates
  if (max(abs(trappingdat$Period),na.rm=T) > max(abs(moon_dates$Period),na.rm=TRUE)) {
    
    # extract trappingdat periods beyond those included in moon_dates
    newperiod = filter(trappingdat,abs(Period)>max(abs(moon_dates$Period),na.rm=TRUE))
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

#' Rewrites file moon_dates.csv with latest trapping dates
#'
#' @example writenewmoons()
#' 
#' 

writenewmoons <- function() {
  moon_dates=update_moon_dates()
write.csv(moon_dates,file="../Rodents/moon_dates.csv",row.names=FALSE) }

