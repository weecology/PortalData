# This script takes a raw .dat file downloaded directly from the Portal weather 
# station, determines if there are any gaps, and appends the new data to the
# database.
# Met445.dat can be used for testing - it has a lot of problems

# written by Erica Christensen 5/2016

library(lubridate)
library(dplyr)
# ==============================================================================
# Load file
# ==============================================================================

# Open raw .dat file of new data
filepath = "~/Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2002_Station/"

metfile = "Met466"

rawdata = read.csv(paste(filepath,metfile,'.dat',sep=''),head=F,sep=',',
                   col.names=c('code','year','jday','hour','precipitation','airtemp','RH'))

# Convert Julian day to month and day
rawdata$date = as.Date(paste(rawdata$year,rawdata$jday),format='%Y %j')
rawdata$month = as.integer(format(rawdata$date,'%m'))
rawdata$day = as.integer(format(rawdata$date,'%d'))
rawdata$timestamp = ymd_hms(paste(rawdata$year,"-",rawdata$month,"-",rawdata$day," ",rawdata$hour/100,":00:00",sep=""))

# Select weather data (Code=101) from battery status data (Code=102) then add battery data as column
weathdat = rawdata[rawdata$code==101,]
battery= rawdata[rawdata$code==102,] %>% select(year,month,day,hour,battv=precipitation)
weathdat=left_join(weathdat,battery,by=c("year","month","day","hour"))

# ==============================================================================
# 1. Quality control
# ==============================================================================

# check for errors in hour (should be 100,200,300,...)
if (any(!(weathdat$hour %in% seq(from=100,to=2400,by=100)))) {
  print('Hour error')
  weathdat = filter(weathdat,hour %in% seq(100,2400,100))
} else {print('Hour ok')}

# check for errors in air temp (i.e. temp > 100C or < -30)
if (any(weathdat$airtemp > 100)) {
  print('Air temp error')
  weathdat = filter(weathdat,airtemp < 100)
}
if (any(weathdat$airtemp < -30)) {
    print('Air temp error')
    weathdat = filter(weathdat,airtemp > -30)
} else {print('Air temp ok')}

# check for errors in rel humidity (either > 100 or < 0)
if (any(weathdat$RH >100)) {
  print('RelHumid error')
  weathdat = filter(weathdat,RH < 100)
} 
if (any(weathdat$RH < 0)) {
  print('RelHumid error')
  weathdat = filter(weathdat,RH > 0)
} else {print('RelHumid ok')}

# check battery status (should be ~12.5)
if (any(weathdat$battv < 11,na.rm=T)) {print('Battery error')} else {print('Battery ok')}

# check that start of new data lines up with end of existing data
#Get max record from overlap data (this works because the last RECORD will always be higher for the old station)
exst_dat = read.csv('~/PortalData/Weather/Portal_weather_overlap.csv')
last = tail(ymd_hms(exst_dat$timestamp[exst_dat$record==max(exst_dat$record)]),n=1)

if (last + 3600==ymd_hms(weathdat$timestamp)[1]) {
  print('dates match')
} else {print('dates do not match')
  print('Looking for data after')
  print(last)
  
  weathdat = subset(weathdat,ymd_hms(timestamp) >=
          last+3600)
  }

#Add RECORD column
weathdat$record=max(exst_dat$record)+1:dim(weathdat)[1]

# plot data to look for outliers/weirdness
plot(weathdat$airtemp,type='l')
plot(weathdat$precipitation)
plot(weathdat$RH,type='l')



# ==============================================================================
# 2. Append new data to file
# ==============================================================================

# get new data columns in correct order
newdata = weathdat[,c("year","month","day","hour","timestamp","record","battv","airtemp","precipitation","RH")]

# append new data
write.table(newdata, file = "~/PortalData/Weather/Portal_weather_overlap.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")
