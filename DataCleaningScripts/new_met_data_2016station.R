# This script checks for new data in the raw .dat file remotely downloaded 
# from the Portal 2016 weather station, 
# determines if there are any gaps, and appends the new data to "Portal_weather.csv


# Modified from new_met_data_to_db.R (Erica Christensen) 3/2017 by Glenda Yenni

library(lubridate)
library(dplyr)
# ==============================================================================
# Load file
# ==============================================================================

# Open raw .dat file

headers = read.csv("./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_MET.dat", skip = 1, header = F, nrows = 1, as.is = T)
rawdata = read.csv("./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_MET.dat", skip = 4, header = F)
colnames(rawdata)= headers
rawdata=rawdata %>% rename(TempAir=AirTC_Avg,Precipitation=Rain_mm_Tot)


# Convert Timestamp to Year, Month, Day, Hour
rawdata=cbind(Year = year(ymd_hms(rawdata$TIMESTAMP)),
              Month = month(ymd_hms(rawdata$TIMESTAMP)),
              Day = day(ymd_hms(rawdata$TIMESTAMP)),
              Hour = hour(ymd_hms(rawdata$TIMESTAMP)),rawdata)
rawdata$Hour[rawdata$Hour==0] = 24 ; rawdata$Hour = 100*rawdata$Hour

# Keep new data
weather=read.csv("./PortalData/Weather/Portal_weather.csv")

newdata=rawdata[rawdata$RECORD>tail(weather$RECORD,n=1),]
# ==============================================================================
# 1. Quality control
# ==============================================================================

# check for errors in hour (should be 100,200,300,...)
if (any(!(newdata$Hour %in% seq(from=100,to=2400,by=100)))) {
  print('Hour error')
  newdata = filter(newdata,Hour %in% seq(100,2400,100))
} else {print('Hour ok')}

# check for errors in air temp (i.e. temp > 100C or < -30)
if (any(newdata$TempAir > 100)) {
  print('AirT error')
  newdata = filter(newdata,TempAir < 100)
}
if (any(newdata$TempAir < -30)) {
  print('TempAir error')
  newdata = filter(newdata,TempAir > -30)
} else {print('AirT ok')}

# check for errors in rel humidity (either > 100 or < 0)
if (any(newdata$RH >100)) {
  print('RelHumid error')
  newdata = filter(newdata,RH < 100)
} 
if (any(newdata$RH < 0)) {
  print('RelHumid error')
  newdata = filter(newdata,RH > 0)
} else {print('RelHumid ok')}

# check battery status (should be ~12.5)
if (any(newdata$BattV < 11)) {print('Battery error')} else {print('Battery ok')}

# check that start of new data lines up with end of existing data
if (tail(ymd_hms(weather$TIMESTAMP),n=1)+3600==ymd_hms(newdata$TIMESTAMP)[1]) {
  print('dates match')
} else {print('dates do not match')}

# plot data to look for outliers/weirdness
plot(newdata$TempAir,type='l')
plot(newdata$Precipitation)
plot(newdata$RH,type='l')

# ==============================================================================
# 2. Append new data to file
# ==============================================================================


# append new data
write.table(newdata, file = "~/PortalData/Weather/Portal_weather.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

# also append new data to overlap file
overlap=newdata %>% select(Year,Month,Day,Hour,TIMESTAMP,RECORD,TempAir=AirTC_Avg,Precipitation=Rain_mm_Tot)
write.table(ovelap, file = "~/PortalData/Weather/Portal_weather_overlap.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")


################################################################################

### Add new storm data to Portal_storms.csv############

# ==============================================================================
# Load file
# ==============================================================================

# Open raw .dat file

stormheaders = read.csv("./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_Storms.dat", skip = 1, header = F, nrows = 1, as.is = T)
stormsnew = read.csv("./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_Storms.dat", skip = 4, header = F)
colnames(stormsnew)= stormheaders

# Keep new data
storms=read.csv("./PortalData/Weather/Portal_storms.csv")

stormsnew=stormsnew[stormsnew$RECORD>max(storms$RECORD),]


# plot data to look for outliers/weirdness
plot(stormsnew$TIMESTAMP,stormsnew$Rain_mm_Tot)


# ==============================================================================
# 2. Append new data to file
# ==============================================================================


# append new data
write.table(stormsnew, file = "~/PortalData/Weather/Portal_storms.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")
