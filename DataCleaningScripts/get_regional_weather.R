`%>%` <- magrittr::`%>%`

#' Reports regional weather data with the data from
#' DAILY GLOBAL HISTORICAL CLIMATOLOGY NETWORK (GHCN-DAILY). 
#' 
#' @example get_regional_weather()

get_regional_weather <- function() {
  
portal4sw_station=readLines('https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/USC00026716.dly')
sansimon_station=readLines('https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/US1AZCH0005.dly')

portal4sw = clean_station_data(portal4sw_station)
sansimon = clean_station_data(sansimon_station)

#Keep only new data
all_4sw = read.csv(file = "Weather/Portal4sw_regional_weather.csv",header=T,
                   colClasses=c("character", rep("integer",3), "character", "integer", 
                                rep("character",3), "Date"))
all_sansimon = read.csv(file = "Weather/Sansimon_regional_weather.csv",header=T,
                        colClasses=c("character", rep("integer",3), "character", "integer", 
                                     rep("character",3), "Date"))

new_4sw=dplyr::setdiff(portal4sw,all_4sw)
new_sansimon=dplyr::setdiff(sansimon,all_sansimon)

return(list(new_4sw,new_sansimon))

}


#' Creates a dataframe from the mess DAILY GLOBAL HISTORICAL CLIMATOLOGY NETWORK (GHCN-DAILY) gives you. 
#' The metadata specify substrings that correspond to columns.
#' However, within a month, the timeseries grows by adding days to the string (as 'columns') rather than as new rows.
#' Pull out values from string and assign to rows, adding a 'day' column, to get the data in a normal long format.
#' Data from regional stations are available at ncdc.noaa.gov/pub/data/ghcn/daily (the GHCN-DAILY timeseries).
#' Metadata are described here: https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
#' 
#' @param stationdata A vector of data in the format of GHCN-DAILY


clean_station_data <- function(stationdata) {

data_out  = data.frame(id=as.character(substr(stationdata,1,11)), stringsAsFactors=FALSE)
data_out$year = as.integer(substr(stationdata,12,15))
data_out$month  = as.integer(substr(stationdata,16,17))
data_out$day = 1
data_out$element  = as.character(substr(stationdata,18,21))
data_out$value  = as.integer(substr(stationdata,22,26))
data_out$measurement_flag  = as.character(substr(stationdata,27,27))
data_out$quality_flag  = as.character(substr(stationdata,28,28))
data_out$source = as.character(substr(stationdata,29,29))

# Build days 2 through 31 as new rows
# Initiate v, m, q, and s 
# (These are indices for the location of the value (v) and it's 3 associated flags (m, q, and s))
v = 22
m = 27
q = 28
s = 29

for(t in 2:31) {
  
  # update counter for the location of the next value (v), and it's 3 associated flags 
  v = v + 8
  m = m + 8
  q = q + 8
  s = s + 8
  
  tmp  = data.frame(id=as.character(substr(stationdata,1,11)))
  tmp$year = as.integer(substr(stationdata,12,15))
  tmp$month  = as.integer(substr(stationdata,16,17))
  tmp$day = t
  tmp$element  = as.character(substr(stationdata,18,21))
  tmp$value  = as.integer(substr(stationdata,v,v+4))
  tmp$measurement_flag  = as.character(substr(stationdata,m,m))
  tmp$quality_flag  = as.character(substr(stationdata,q,q))
  tmp$source  = as.character(substr(stationdata,s,s))
  
  data_out = rbind(data_out,tmp)
  
}

data_out[data_out == -9999] = NA

data_out = data_out %>% dplyr::group_by(year,month,day,element) %>%
  dplyr::arrange(year,month,day) %>% tidyr::drop_na(value:source) %>%
  dplyr::mutate(date = as.Date(paste(year,month,day,sep="-"),"%Y-%m-%d")) %>%
  dplyr::filter(is.integer(year),is.integer(month),is.integer(day))

return(data_out)
}

#' Appends new regional weather data
#'
#'
#'
#' @example append_regional_weather()

append_regional_weather <- function() {
  
  data=get_regional_weather()
  
  # append new data
  write.table(data[1], file = "Weather/Portal4sw_regional_weather.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")
  
  write.table(data[2], file = "Weather/Sansimon_regional_weather.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")
  
}
