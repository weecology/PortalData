# This function checks for new data in the raw .dat file remotely downloaded 
# from the Portal 2016 weather station, 
# determines if there are any gaps, and appends the new data to "Portal_weather.csv

`%>%` <- magrittr::`%>%`

# ==============================================================================
# Load files, assign column names, and keep new data
# ==============================================================================


new_met_data <- function() {

# Open raw MET.dat file, read in headers and data separately (to preserve data types), then assign colnames

headers = read.csv(url('https://www.dropbox.com/s/14y7kpp81jh4ex2/CR1000_MET.dat?dl=1'), skip = 1, header = F, nrows = 1, as.is = T)
rawdata = read.csv(url('https://www.dropbox.com/s/14y7kpp81jh4ex2/CR1000_MET.dat?dl=1'), skip = 4, header = F)
colnames(rawdata)= headers
rawdata=rawdata %>% dplyr::rename(TempAir=AirTC_Avg,Precipitation=Rain_mm_Tot)

# Open raw Storms.dat file, read in headers and data separately (to preserve data types), then assign colnames

stormheaders = read.csv(url("https://www.dropbox.com/s/41y62qi26hcmh2y/CR1000_Storms.dat?dl=1"), skip = 1, header = F, nrows = 1, as.is = T)
stormsnew = read.csv(url("https://www.dropbox.com/s/41y62qi26hcmh2y/CR1000_Storms.dat?dl=1"), skip = 4, header = F)
colnames(stormsnew)= stormheaders


# Convert Timestamp
rawdata$TIMESTAMP = lubridate::ymd_hms(rawdata$TIMESTAMP)
stormsnew$TIMESTAMP = lubridate::ymd_hms(stormsnew$TIMESTAMP)

#Get Year, Month, Day, Hour
rawdata=cbind(Year = lubridate::year(rawdata$TIMESTAMP),
              Month = lubridate::month(rawdata$TIMESTAMP),
              Day = lubridate::day(rawdata$TIMESTAMP),
              Hour = lubridate::hour(rawdata$TIMESTAMP),rawdata)
rawdata$Hour[rawdata$Hour==0] = 24 ; rawdata$Hour = 100*rawdata$Hour

# Load existing data for comparison
weather=read.csv("../Weather/Portal_weather.csv")
weather$TIMESTAMP = lubridate::ymd_hms(weather$TIMESTAMP)
storms=read.csv("../Weather/Portal_storms.csv")
storms$TIMESTAMP = lubridate::ymd_hms(storms$TIMESTAMP)

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
write.table(data[1], file = "../Weather/Portal_weather.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")
  write.table(data[3], file = "../Weather/Portal_storms.csv", 
              row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

# also append new data to overlap file
overlap=as.data.frame(data[1]) %>% dplyr::select(Year,Month,Day,Hour,TIMESTAMP,RECORD,BattV,TempAir,Precipitation,RH)
overlap$TIMESTAMP=lubridate::ymd_hms(overlap$TIMESTAMP)
write.table(overlap, file = "../Weather/Portal_weather_overlap.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

}


