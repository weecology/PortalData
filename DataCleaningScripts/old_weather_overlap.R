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
filepath = "./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2002_Station/"

metfile = "Met459"

rawdata = read.csv(paste(filepath,metfile,'.dat',sep=''),head=F,sep=',',col.names=c('Code','Year','Jday','Hour','Precipitation','TempAir','RH'))

# Convert Julian day to month and day
rawdata$date = as.Date(paste(rawdata$Year,rawdata$Jday),format='%Y %j')
rawdata$Month = as.integer(format(rawdata$date,'%m'))
rawdata$Day = as.integer(format(rawdata$date,'%d'))
rawdata$TimeStamp = ymd_hms(paste(rawdata$Year,"-",rawdata$Month,"-",rawdata$Day," ",rawdata$Hour/100,":00:00",sep=""))

# Select weather data (Code=101) from battery status data (Code=102) then add battery data as column
weathdat = rawdata[rawdata$Code==101,]
battery= rawdata[rawdata$Code==102,] %>% select(Year,Month,Day,Hour,BattV=Precipitation)
weathdat=left_join(weathdat,battery,by=c("Year","Month","Day","Hour"))

# ==============================================================================
# 1. Quality control
# ==============================================================================

# check for errors in hour (should be 100,200,300,...)
if (any(!(weathdat$Hour %in% seq(from=100,to=2400,by=100)))) {
  print('Hour error')
  weathdat = filter(weathdat,Hour %in% seq(100,2400,100))
} else {print('Hour ok')}

# check for errors in air temp (i.e. temp > 100C or < -30)
if (any(weathdat$TempAir > 100)) {
  print('TempAir error')
  weathdat = filter(weathdat,TempAir < 100)
}
if (any(weathdat$TempAir < -30)) {
    print('TempAir error')
    weathdat = filter(weathdat,TempAir > -30)
} else {print('TempAir ok')}

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
if (any(rawdata[rawdata$Code==102,5] < 11)) {print('Battery error')} else {print('Battery ok')}

# check that start of new data lines up with end of existing data
#Get max record from overlap data (this works because the last RECORD will always be higher for the old station)
exst_dat = read.csv('~/PortalData/Weather/Portal_weather_overlap.csv')

if (tail(ymd_hms(exst_dat$TimeStamp[exst_dat$Record==max(exst_dat$Record)]),n=1)+3600==ymd_hms(weathdat$TimeStamp)[1]) {
  print('dates match')
} else {print('dates do not match')}

#Add RECORD column
weathdat$Record=max(exst_dat$Record)+1:dim(weathdat)[1]

# plot data to look for outliers/weirdness
plot(weathdat$TempAir,type='l')
plot(weathdat$Precipitation)
plot(weathdat$RH,type='l')



# ==============================================================================
# 2. Append new data to file
# ==============================================================================

# get new data columns in correct order
newdata = weathdat[,c("Year","Month","Day","Hour","TimeStamp","Record","BattV","TempAir","Precipitation","RH")]

# append new data
write.table(newdata, file = "~/PortalData/Weather/Portal_weather_overlap.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")
