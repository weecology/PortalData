# This function checks for new data in the raw .dat file remotely downloaded 
# from the Portal 2016 weather station, 
# determines if there are any gaps, and appends the new data to "Portal_weather.csv


library(lubridate)
library(dplyr)


# ==============================================================================
# Load files, assign column names, and keep new data
# ==============================================================================


new_met_data <- function() {

# Open raw MET.dat file, read in headers and data separately (to preserve data types), then assign colnames
  
headers = read.csv('./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_MET.dat', skip = 1, header = F, nrows = 1, as.is = T)
rawdata = read.csv('./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_MET.dat', skip = 4, header = F)
colnames(rawdata)= headers
rawdata=rawdata %>% rename(TempAir=AirTC_Avg,Precipitation=Rain_mm_Tot)

# Open raw Storms.dat file, read in headers and data separately (to preserve data types), then assign colnames

stormheaders = read.csv("./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_Storms.dat", skip = 1, header = F, nrows = 1, as.is = T)
stormsnew = read.csv("./Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_Storms.dat", skip = 4, header = F)
colnames(stormsnew)= stormheaders


# Convert Timestamp
rawdata$TIMESTAMP = ymd_hms(rawdata$TIMESTAMP)
stormsnew$TIMESTAMP = ymd_hms(stormsnew$TIMESTAMP)

#Get Year, Month, Day, Hour
rawdata=cbind(Year = year(rawdata$TIMESTAMP),
              Month = month(rawdata$TIMESTAMP),
              Day = day(rawdata$TIMESTAMP),
              Hour = hour(rawdata$TIMESTAMP),rawdata)
rawdata$Hour[rawdata$Hour==0] = 24 ; rawdata$Hour = 100*rawdata$Hour

# Load existing data for comparison
weather=read.csv("~/PortalData/Weather/Portal_weather.csv")
weather$TIMESTAMP = ymd_hms(weather$TIMESTAMP)
storms=read.csv("~/PortalData/Weather/Portal_storms.csv")
storms$TIMESTAMP = ymd_hms(storms$TIMESTAMP)

#Keep only new data
newdata=rawdata[rawdata$TIMESTAMP>tail(weather$TIMESTAMP,n=1),] 
stormsnew=stormsnew[stormsnew$TIMESTAMP>tail(storms$TIMESTAMP,n=1),]

return(list(newdata,weather,stormsnew,storms))
  
}



# ==============================================================================
# 2. Append new data to repo files
# ==============================================================================

append_weather <- function(data) {

# append new data
write.table(data[1], file = "~/PortalData/Weather/Portal_weather.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")
  write.table(data[3], file = "~/PortalData/Weather/Portal_storms.csv", 
              row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

# also append new data to overlap file
overlap=as.data.frame(data[1]) %>% select(Year,Month,Day,Hour,TIMESTAMP,RECORD,BattV,TempAir,Precipitation,RH)
overlap$TIMESTAMP=ymd_hms(overlap$TIMESTAMP)
write.table(overlap, file = "~/PortalData/Weather/Portal_weather_overlap.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

}


