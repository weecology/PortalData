# This function checks for new data in the raw .dat file remotely downloaded 
# from the Portal 2016 weather station, 
# determines if there are any gaps, and appends the new data to "Portal_weather.csv"

`%>%` <- magrittr::`%>%`

# ==============================================================================
# Load files, assign column names, and keep new data
# ==============================================================================


new_met_data <- function() {

# Pull raw data (latest 48 records)

rawdata = htmltab::htmltab(doc='http://166.153.133.121/?command=TableDisplay&table=MET&records=100', sep = "")

rawdata=rawdata %>% dplyr::rename(TempAir=AirTC_Avg,Precipitation=Rain_mm_Tot)

# Pull raw storms data (latest 100 records)

stormsnew = htmltab::htmltab(doc="http://166.153.133.121/?command=TableDisplay&table=Storms&records=100", sep = "")

# Convert Timestamp
rawdata$TimeStamp = lubridate::ymd_hms(rawdata$TimeStamp)
stormsnew$TimeStamp = lubridate::ymd_hms(stormsnew$TimeStamp)
class(stormsnew$Rain_mm_Tot)="numeric"

#Get Year, Month, Day, Hour
rawdata=cbind(Year = lubridate::year(rawdata$TimeStamp),
              Month = lubridate::month(rawdata$TimeStamp),
              Day = lubridate::day(rawdata$TimeStamp),
              Hour = lubridate::hour(rawdata$TimeStamp),rawdata)
rawdata$Hour[rawdata$Hour==0] = 24 ; rawdata$Hour = 100*rawdata$Hour

# Load existing data for comparison
weather=read.csv("../Weather/Portal_weather.csv")
  weather$TimeStamp = lubridate::ymd_hms(weather$TimeStamp)
storms=read.csv("../Weather/Portal_storms.csv")
  storms$TimeStamp = lubridate::ymd_hms(storms$TimeStamp)

#Keep only new data
newdata=rawdata[rawdata$TimeStamp>tail(weather$TimeStamp,n=1),] 
stormsnew=stormsnew[stormsnew$TimeStamp>tail(storms$TimeStamp,n=1),]

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
overlap=as.data.frame(data[1]) %>% dplyr::select(Year,Month,Day,Hour,TimeStamp,Record,BattV,TempAir,Precipitation,RH)
overlap$TimeStamp=lubridate::ymd_hms(overlap$TimeStamp)
write.table(overlap, file = "../Weather/Portal_weather_overlap.csv", 
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

}


