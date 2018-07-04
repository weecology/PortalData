`%>%` <- magrittr::`%>%`

#' Selects new weather data
#'
#'
#'
#' @example new_met_data()
#'
#'
#'
# This function checks for new data at the datalogger-hosted website

new_met_data <- function() {
  
  #httr::set_config(httr::timeout(seconds = 120))

# Pull raw data (latest week of records, plus some overlap for saftey) & rename columns

rawdata = htmltab::htmltab(doc='http://166.153.133.121/?command=TableDisplay&table=MET&records=1000', sep = "")  %>% 

  dplyr::rename(airtemp=AirTC_Avg,precipitation=Rain_mm_Tot,timestamp=TimeStamp,record=Record,battv=BattV)

# Pull raw storms data (latest 2500 records) & rename columns

stormsnew = htmltab::htmltab(doc="http://166.153.133.121/?command=TableDisplay&table=Storms&records=2500", sep = "")  %>%
 
  dplyr::rename(timestamp = TimeStamp, record = Record, battv = BattV_Min, precipitation = Rain_mm_Tot)

# Convert Timestamp
rawdata$timestamp = lubridate::ymd_hms(rawdata$timestamp)
stormsnew$timestamp = lubridate::ymd_hms(stormsnew$timestamp)

#Get Year, Month, Day, Hour
rawdata=cbind(year = lubridate::year(rawdata$timestamp),
              month = lubridate::month(rawdata$timestamp),
              day = lubridate::day(rawdata$timestamp),
              hour = lubridate::hour(rawdata$timestamp),rawdata)

#Fix hour and day so midnight=2400
rawdata$hour[rawdata$hour==0] = 24 ; rawdata$hour = 100*rawdata$hour
rawdata$day[rawdata$hour==2400] = rawdata$day[which(rawdata$hour==2400)-1]
rawdata$month[rawdata$hour==2400] = rawdata$month[which(rawdata$hour==2400)-1]
rawdata$year[rawdata$hour==2400] = rawdata$year[which(rawdata$hour==2400)-1]

#Fix column classes
rawdata$record = as.integer(rawdata$record)
rawdata[,7:25] = lapply(rawdata[,7:25],as.numeric)

class(stormsnew$record)="numeric"
class(stormsnew$battv)="numeric"
class(stormsnew$precipitation)="numeric"

# Load existing data for comparison
weather=read.csv("../Weather/Portal_weather.csv")
  weather$timestamp = lubridate::ymd_hms(weather$timestamp)

storms=read.csv("../Weather/Portal_storms.csv")
  storms$timestamp = lubridate::ymd_hms(storms$timestamp)

#Keep only new data
newdata=rawdata[rawdata$timestamp>tail(weather$timestamp,n=1),]
stormsnew=stormsnew[stormsnew$timestamp>tail(storms$timestamp,n=1),]

return(list(newdata,weather,stormsnew,storms))

}

#' Appends new weather data
#'
#'
#'
#' @example append_weather()
#'
#'
#'

append_weather <- function() {

  data=new_met_data()

# append new data
write.table(data[1], file = "../Weather/Portal_weather.csv",
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

  write.table(data[3], file = "../Weather/Portal_storms.csv",
              row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

# also append new data to overlap file
overlap=as.data.frame(data[1]) %>% dplyr::select(year,month,day,hour,timestamp,record,battv,airtemp,precipitation,RH)
overlap$timestamp=lubridate::ymd_hms(overlap$timestamp)
write.table(overlap, file = "../Weather/Portal_weather_overlap.csv",
            row.names = F, col.names = F, na = "", append = TRUE, sep = ",")

}


