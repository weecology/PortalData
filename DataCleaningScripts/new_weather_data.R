#' Functions for downloading and processing the weather data
#'
#' See `weather_server_update.py` for code that pulls the data from
#' the data logger and posts it to the web.

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
  
# To read from .dat file
# header=read.table("~/Dropbox (UFL)/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/517_CR1000_remote_MET.dat",
#                    skip = 1, nrow = 1, header = FALSE, sep=",", stringsAsFactors = FALSE)
# 
# rawdata=read.table("~/Dropbox (UFL)/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/517_CR1000_remote_MET.dat",
#                    skip = 4, header = FALSE,sep=",") %>%
#   `colnames<-`(header) %>%
#   dplyr::rename(airtemp=AirTC_Avg,precipitation=Rain_mm_Tot,timestamp=TIMESTAMP,record=RECORD,
#                  battv=BattV_Avg,soiltemp=Soil_C_Avg,PTemp_C=PTemp_C_Avg,BP_mmHg_Avg=BP_mmHg)
# 
# header_storms=read.table("~/Dropbox (UFL)/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_remote_storms.dat",
#                   skip = 1, nrow = 1, header = FALSE, sep=",", stringsAsFactors = FALSE)
# 
# stormsnew=read.table("~/Dropbox (UFL)/Portal/PORTAL_primary_data/Weather/Raw_data/2016_Station/CR1000_remote_storms.dat",
#                    skip = 4, header = FALSE,sep=",") %>%
#   `colnames<-`(header_storms) %>%
#   dplyr::rename(precipitation=Rain_mm_Tot,timestamp=TIMESTAMP,record=RECORD,battv=BattV_Min)

today <- lubridate::ymd_hms(gsub(":\\d+:\\d+",":00:00",Sys.time()))
  # Pull raw data (latest week of records, plus some overlap for safety) & rename columns
  message("Pulling raw weather data")

rawdata <- suppressMessages(htmltab::htmltab(doc='http://157.230.136.69/weather-data.html', sep = "", 
                                             which = 1)) %>%
  dplyr::rename(airtemp=AirTC_Avg,precipitation=Rain_mm_Tot,timestamp=TimeStamp,record=Record,
                battv=BattV_Avg,soiltemp=Soil_C_Avg,PTemp_C=PTemp_C_Avg,BP_mmHg_Avg=BP_mmHg)

  message("Raw weather data loaded")

# Pull raw storms data (latest 2500 records) & rename columns
message("Pulling raw storms data")

stormsnew <- suppressMessages(htmltab::htmltab(doc="http://157.230.136.69/storms-data.html", sep = "", 
                                               which = 1)) %>%
  dplyr::rename(timestamp = TimeStamp, record = Record, battv = BattV_Min, precipitation = Rain_mm_Tot)

  message("Raw storms data loaded")

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
rawdata[,c(1:4,6)] <- lapply(rawdata[,c(1:4,6)],as.integer)
rawdata[,7:26] <- lapply(rawdata[,7:26],as.numeric)

class(stormsnew$record)="numeric"
class(stormsnew$battv)="numeric"
class(stormsnew$precipitation)="numeric"

# New weather table
weather <- read.csv("Weather/Portal_weather.csv") 
weather$timestamp <- lubridate::ymd_hms(weather$timestamp)
weather[,c(1:4,6)] <- lapply(weather[,c(1:4,6)],as.integer)
weather[,7:25] <- lapply(weather[,7:25],as.numeric)
last_date <- max(weather$timestamp)
weather <- weather %>%
  dplyr::add_row(timestamp = lubridate::ymd_hms(seq.POSIXt(last_date+3600, today, by = "1 hour")),
         year = lubridate::year(timestamp), month = lubridate::month(timestamp),
         day = lubridate::day(timestamp), hour = 100*lubridate::hour(timestamp))
weather$day[weather$hour==0] = weather$day[which(weather$hour==0)-1]
weather$month[weather$hour==0] = weather$month[which(weather$hour==0)-1]
weather$year[weather$hour==0] = weather$year[which(weather$hour==0)-1]
weather$hour[weather$hour==0] = 2400

newdata <- suppressMessages(coalesce_join(weather, rawdata, 
                                          by = c("year", "month", "day", "hour", "timestamp")))

# New storms table
storms <- read.csv("Weather/Portal_storms.csv")
  storms$timestamp <- lubridate::ymd_hms(storms$timestamp)
  # Keep only new data
  
  stormsnew <- stormsnew[stormsnew$timestamp>tail(storms$timestamp,n=1),]

# New overlap table
overlap <- read.csv("Weather/Portal_weather_overlap.csv") %>%
  dplyr::mutate(timestamp = lubridate::ymd_hms(timestamp))
                
newoverlapdata <- newdata %>%
  dplyr::filter(timestamp >= min(overlap$timestamp)) %>%
  dplyr::select(year,month,day,hour,timestamp,record,battv,airtemp,precipitation,RH)

newoverlap <- suppressMessages(coalesce_join(overlap, newoverlapdata, 
                                          by = c("year", "month", "day", "hour", "timestamp")))

return(list(newdata,stormsnew,newoverlap))

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

  data <- new_met_data()

# append new data
write.table(data[1], file = "Weather/Portal_weather.csv",
            row.names = FALSE, col.names = TRUE, na = "", sep = ",")

write.table(data[2], file = "Weather/Portal_storms.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")

# also append new data to overlap file
write.table(data[3], file = "Weather/Portal_weather_overlap.csv",
            row.names = FALSE, col.names = TRUE, na = "", sep = ",")

}

#' Full_join in dplyr, but with coalesce 
#' Replace NAs with values where available automatically in table join
#' via https://alistaire.rbind.io/blog/coalescing-joins/
#'
#'
#' @example coalesce_join()
#'

coalesce_join <- function(x, y, 
                          by = NULL, suffix = c(".x", ".y"), 
                          join = dplyr::full_join, ...) {
  joined <- join(x, y, by = by, suffix = suffix, ...)
  # names of desired output
  cols <- union(names(x), names(y))
  
  to_coalesce <- names(joined)[!names(joined) %in% cols]
  suffix_used <- suffix[ifelse(endsWith(to_coalesce, suffix[1]), 1, 2)]
  # remove suffixes and de-duplicate
  to_coalesce <- unique(substr(
    to_coalesce, 
    1, 
    nchar(to_coalesce) - nchar(suffix_used)
  ))
  
  coalesced <- purrr::map_dfc(to_coalesce, ~dplyr::coalesce(
    joined[[paste0(.x, suffix[1])]], 
    joined[[paste0(.x, suffix[2])]]
  ))
  names(coalesced) <- to_coalesce
  
  dplyr::bind_cols(joined, coalesced)[cols]
}
