`%>%` <- magrittr::`%>%`

#' Reports regional weather data with the data from
#' DAILY GLOBAL HISTORICAL CLIMATOLOGY NETWORK (GHCN-DAILY).
#' Metadata are described here: 
#' https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/doc/GHCND_documentation.pdf
#' 
#' 
#' @example get_regional_weather()

get_regional_weather <- function() {
  
portal4sw = read.csv(
  'https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USC00026716.csv') %>%
  dplyr::rename_all(.funs = tolower) %>%
  dplyr::mutate_all(as.character) %>% 
  dplyr::mutate_at(c("latitude","longitude","elevation","prcp","snow","snwd","tmax","tmin","dapr","dasf",
                     "mdpr","mdsf","tobs","wt01","wt03","wt04","wt05","wt11"), as.numeric) %>%
  dplyr::mutate_at("date",as.Date) %>%
  dplyr::mutate(day = lubridate::day(date), 
                month = lubridate::month(date), 
                year = lubridate::year(date)) %>%
  dplyr::select(year, month, day, dplyr::everything())
  

sansimon = read.csv(
  'https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/US1AZCH0005.csv') %>%
  dplyr::rename_all(.funs = tolower) %>%
  dplyr::mutate_all(as.character) %>% 
  dplyr::mutate_at(c("latitude","longitude","elevation","prcp","snow","snwd","wesd","wesf"), as.numeric) %>%
  dplyr::mutate_at("date",as.Date) %>%
  dplyr::mutate(day = lubridate::day(date), 
                month = lubridate::month(date), 
                year = lubridate::year(date)) %>%
  dplyr::select(year, month, day, dplyr::everything())


#Keep only new data
all_4sw = read.csv(file = "Weather/Portal4sw_regional_weather.csv",header=T, stringsAsFactors=FALSE)
all_4sw$date = lubridate::ymd(all_4sw$date)

all_sansimon = read.csv(file = "Weather/Sansimon_regional_weather.csv",header=T, stringsAsFactors=FALSE)
all_sansimon$date = lubridate::ymd(all_sansimon$date) 

new_4sw = dplyr::setdiff(portal4sw,all_4sw)
new_sansimon = dplyr::setdiff(sansimon,all_sansimon)

return(list(new_4sw,new_sansimon))

}

#' Appends new regional weather data
#'
#'
#'
#' @example append_regional_weather()

append_regional_weather <- function() {
  
  data = get_regional_weather()
  
  # append new data
  write.table(data[1], file = "Weather/Portal4sw_regional_weather.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")
  
  write.table(data[2], file = "Weather/Sansimon_regional_weather.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")
  
}
