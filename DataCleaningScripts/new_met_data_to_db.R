# This script takes a raw .dat file downloaded directly from the Portal weather 
# station, determines if there are any gaps, and appends the new data to the
# database.
# Met445.dat can be used for testing - it has a lot of problems

# written by Erica Christensen 5/2016

setwd('C:/Users/EC/Desktop/git/PortalData')


library(dplyr)
# ==============================================================================
# Load file
# ==============================================================================

# Open raw .dat file of new data
filepath = "C:\\Users\\EC\\Dropbox\\Portal\\PORTAL_primary_data\\Weather\\Raw_data\\2002_Station\\"

metfile = "Met457"

rawdata = read.csv(paste(filepath,metfile,'.dat',sep=''),head=F,sep=',',col.names=c('Code','Year','Jday','Hour','Precipitation','TempAir','RelHumid'))

# Convert Julian day to month and day
rawdata$date = as.Date(paste(rawdata$Year,rawdata$Jday),format='%Y %j')
rawdata$Month = as.integer(format(rawdata$date,'%m'))
rawdata$Day = as.integer(format(rawdata$date,'%d'))

# Select weather data (Code=101) from battery status data (Code=102)
weathdat = rawdata[rawdata$Code==101,]

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
if (any(weathdat$RelHumid >100)) {
  print('RelHumid error')
  weathdat = filter(weathdat,RelHumid < 100)
} 
if (any(weathdat$RelHumid < 0)) {
  print('RelHumid error')
  weathdat = filter(weathdat,RelHumid > 0)
} else {print('RelHumid ok')}

# check battery status (should be ~12.5)
if (any(rawdata[rawdata$Code==102,5] < 11)) {print('Battery error')} else {print('Battery ok')}

# check that start of new data lines up with end of existing data
exst_dat = read.csv('Weather/Portal_weather.csv')
last_old = strptime(paste(tail(exst_dat$Year,1),tail(exst_dat$Month,1),tail(exst_dat$Day,1),tail(exst_dat$Hour/100,1)),format='%Y %m %d %H')
first_new = strptime(paste(weathdat$Year[1],weathdat$Month[1],weathdat$Day[1],weathdat$Hour[1]/100),format='%Y %m %d %H')
if (first_new == last_old+3600) {
  print('dates match')
} else {print('dates do not match')}

# plot data to look for outliers/weirdness
plot(weathdat$TempAir,type='l')
plot(weathdat$Precipitation)
plot(weathdat$RelHumid,type='l')

# ==============================================================================
# 2. Append new data to file
# ==============================================================================

# get new data columns in correct order
newdata = weathdat[,c('Year','Month','Day','Hour','TempAir','Precipitation')]

# append new data
write.table(newdata, file = "Weather/Portal_weather.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")
