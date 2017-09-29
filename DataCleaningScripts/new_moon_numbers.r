# some code to match new moon dates to period sampling dates
# new moon dates downloaded from http://www.somacon.com/p570.php
#   --data from this site is a csv with columns: date, time, phase, phaseid, datetime, timestamp, friendlydate

library(dplyr)
library(lubridate)
library(htmltab)


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
  for (p in unique(dat$period)) {
    perioddate <- dat %>% filter(period==p) %>% filter(censusdate == min(censusdate)) %>% head(1) %>% select(period,censusdate)
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
#' @example closest_newmoon(as.Date('2017-02-26'),moon_dates$newmoondate)
#' 
closest_newmoon = function(target_date,newmoondates) {
  loc = which.min(abs(target_date-newmoondates))
  closest = newmoondates[loc]
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
  moon_dates=read.csv("./Rodents/moon_dates.csv",stringsAsFactors = FALSE)
  moon_dates$newmoondate = as.Date(moon_dates$newmoondate)
  moon_dates$censusdate = as.Date(moon_dates$censusdate)
  # load rodent trapping data
  trappingdat=read.csv("./Rodents/Portal_rodent_trapping.csv")  
  trappingdat$censusdate = as.Date(paste(trappingdat$year,trappingdat$month,trappingdat$day,sep='-'))
  
  
  # proceed only if trappingdat has more recent dates than moon_dates
  if (max(abs(trappingdat$period),na.rm=T) > max(abs(moon_dates$period),na.rm=TRUE)) {  
   
  #Get dates and period numbers of new data only  
    # extract trappingdat periods beyond those included in moon_dates
    newperiod = filter(trappingdat,abs(period)>max(abs(moon_dates$period),na.rm=TRUE))
    # reduce new trapping data to two columns: Period and CensusDate
    newperiod_dates = find_first_trap_night(newperiod)  
     
  # get new moon dates
    #define date range for newmoon dates, shifting back a month just to not skip any
    first=newperiod_dates$censusdate[1]-30
    year=year(first)
    month=month(first)
    #pull new moon dates from navy.mil
    newmoondates=htmltab(doc=paste("http://aa.usno.navy.mil/cgi-bin/aa_phases.pl?year=",year,"&month=",month,"&day=1&nump=50&format=t", sep=""))
    newmoondates=gsub('.{6}$', '', newmoondates$"Date and Time (Universal Time)"[newmoondates$"Moon Phase" == "New Moon"])
    newmoondates = as.Date(ymd(newmoondates, format='%Y %m %d'))
  
  #Set up dataframe for new moon dates to be added
  newmoons=data.frame(newmoonnumber= NA, newmoondate = as.Date(newmoondates), period = NA, censusdate = as.Date(NA))
    #keep only newmoon dates past those currently assigned a newmoonnumber
    newmoons=filter(newmoons,newmoondate>max(moon_dates$newmoondate,na.rm=TRUE))
    #add newmoonnumbers to newmoondates
    newmoons$newmoonnumber=max(moon_dates$newmoonnumber)+1:dim(newmoons)[1]

  #Match new census dates to moon dates

    # match new period to closest NewMoonDate, 
    for(i in 1:dim(newperiod_dates)[1]) {
      closest = closest_newmoon(newperiod_dates$censusdate[i],newmoondates)
      newdate=which(newmoons$newmoondate==closest)
      newmoons$censusdate[newdate]=newperiod_dates$censusdate[i]
      newmoons$period[newdate]=newperiod_dates$period[i]
        }
    
    #Only keep newmoon dates up to latest census
    
    newmoons=newmoons %>% subset(period <= max(abs(newmoons$period),na.rm=TRUE))
    
      #append all new rows to moon_dates data frame
      moon_dates=bind_rows(moon_dates,newmoons)
      
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
write.csv(moon_dates,file="./Rodents/moon_dates.csv",row.names=FALSE) 
}

