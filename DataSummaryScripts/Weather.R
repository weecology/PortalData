#A function to summarize hourly weather data
#with options to summarize by day (level=daily) or month (level=monthly)

library(dtplyr)
library(dplyr)
library(tidyr)
library(lubridate)

weather <- function(level) {
  
  weather_new=read.csv('~/PortalData/Weather/Portal_weather.csv', na.strings=c(""), stringsAsFactors = FALSE)
  weather_old=read.csv('~/PortalData/Weather/Portal_weather_19801989.csv', na.strings=c("-99"), stringsAsFactors = FALSE)
  #NDVI=read.csv('~/PortalData/NDVI/NDVI.csv', na.strings=c("-99"), stringsAsFactors = FALSE)
  
  # Data cleanup
  

  
  
  ###########Summarise by Day ----------------------
  days = weather_new %>% 
    group_by(Year, Month, Day) %>%
    summarize(MinTemp=min(TempAir),MaxTemp=max(TempAir),MeanTemp=mean(TempAir),Precipitation=sum(Precipitation))
  
  weather=bind_rows(weather_old[1:3442,],days)
  
if (level=='Monthly') {
  
  ##########Summarise by Month -----------------
  
  weather = weather %>% 
    group_by(Year, Month) %>%
    summarize(MinTemp=min(MinTemp,na.rm=T),MaxTemp=max(MaxTemp,na.rm=T),MeanTemp=mean(MeanTemp,na.rm=T),Precipitation=sum(Precipitation,na.rm=T))
}

  
  return(weather)
}