`%>%` <- magrittr::`%>%`

#' Compiles all regional weather data with the data from
#' Wunderground (www.wunderground.com) in the Rodeo, NM region.
#' 
#' @example regional_wunder(stationid)

regional_wunder <- function(stationid) {

  tryCatch(
    {
    rodeo <- jsonlite::fromJSON(
      paste('https://api.weather.com/v2/pws/observations/hourly/7day?stationId=',stationid,'&format=json&units=m&apiKey=',Sys.getenv("WU_API_KEY"), sep=""))$observations
    rodeo <- dplyr::bind_cols(rodeo[,1:14], rodeo$metric) %>%
      dplyr::rename_all(.funs = tolower) %>%
      dplyr::select(-epoch,-obstimeutc) %>%
      dplyr::slice(1:(dplyr::n()-2)) %>%
      dplyr::rename(timestamp = obstimelocal, latitude = lat, longitude = lon) %>%
      dplyr::mutate_all(as.character) %>% 
      dplyr::mutate_at(tail(names(.), 32), as.numeric) %>%
      dplyr::mutate(timestamp = round(lubridate::ymd_hms(timestamp), units="hours")) %>%
      dplyr::mutate(day = lubridate::day(timestamp), 
                    month = lubridate::month(timestamp), 
                    year = lubridate::year(timestamp),
                    hour = lubridate::hour(timestamp)) %>%
      dplyr::select(year, month, day, hour, timestamp, dplyr::everything())
    #Fix hour and day so midnight=2400
    rodeo$hour[rodeo$hour==0] = 24 ; rodeo$hour = 100*rodeo$hour
    rodeo$day[rodeo$hour==2400] = rodeo$day[which(rodeo$hour==2400)-1]
    rodeo$month[rodeo$hour==2400] = rodeo$month[which(rodeo$hour==2400)-1]
    rodeo$year[rodeo$hour==2400] = rodeo$year[which(rodeo$hour==2400)-1]

  return(rodeo)
    },
  error=function(e) {
    message(paste('error in', stationid))
    print(e)
    return(NULL)
  },
  warning=function(w) {
    message(paste('warning in', stationid))
    print(w)
    return(NULL)
  }
  )
}

#' Reports regional weather data with the data from Wunderground (www.wunderground.com) and 
#' DAILY GLOBAL HISTORICAL CLIMATOLOGY NETWORK (GHCN-DAILY).
#' Metadata are described here: 
#' https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/doc/GHCND_documentation.pdf
#' 
#' 
#' @example get_regional_weather()

get_regional_weather <- function() {
  
  options(dplyr.summarise.inform = FALSE)  
  
# Portal 4sw station
  portal4sw <- read.csv(
    'https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USC00026716.csv') %>%
    dplyr::rename_all(.funs = tolower) %>%
    dplyr::mutate_all(as.character) %>% 
    dplyr::mutate_at(c("latitude","longitude","elevation","prcp","snow","snwd","tmax","tmin","dapr","dasf",
                       "mdpr","mdsf","tobs","wt01","wt03","wt04","wt05","wt11"), as.numeric) %>%
    dplyr::mutate_at("date",as.Date) %>%
    dplyr::mutate(day = lubridate::day(date), 
                  month = lubridate::month(date), 
                  year = lubridate::year(date),
                  prcp = prcp/10,
                  tmax = tmax/10,
                  tmin = tmin/10, 
                  tobs = tobs/10) %>%
    dplyr::select(year, month, day, dplyr::everything())
  all_4sw <- read.csv(file = "Weather/Portal4sw_regional_weather.csv",header=T, stringsAsFactors=FALSE)
    all_4sw$date <- lubridate::ymd(all_4sw$date)
    new_4sw <- dplyr::setdiff(portal4sw,all_4sw) %>% dplyr::filter(year>2010)

# San Simon station
  sansimon <- read.csv(
    'https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/US1AZCH0005.csv') %>%
    dplyr::rename_all(.funs = tolower) %>%
    dplyr::mutate_all(as.character) %>% 
    dplyr::mutate_at(c("latitude","longitude","elevation","prcp","snow","snwd","wesd","wesf"), as.numeric) %>%
    dplyr::mutate_at("date",as.Date) %>%
    dplyr::mutate(day = lubridate::day(date), 
                  month = lubridate::month(date), 
                  year = lubridate::year(date),
                  prcp = prcp/10) %>%
    dplyr::select(year, month, day, dplyr::everything())
  all_sansimon <- read.csv(file = "Weather/Sansimon_regional_weather.csv",header=T, stringsAsFactors=FALSE)
    all_sansimon$date <- lubridate::ymd(all_sansimon$date) 
    new_sansimon <- dplyr::setdiff(sansimon,all_sansimon)

# All wunderground stations
  stationids <- c("KNMRODEO13","KAZSANSI26","KNMRODEO11","KAZPORTA10","KNMRODEO8","KNMANIMA10","KNMANIMA15")  
  rodeo <- lapply(stationids,regional_wunder) %>% dplyr::bind_rows()
  all_rodeo <- read.csv(file = "Weather/Rodeo_regional_weather.csv",header=TRUE, stringsAsFactors=FALSE)
    all_rodeo$timestamp <- lubridate::ymd_hms(all_rodeo$timestamp) 
    new_rodeo <- dplyr::anti_join(rodeo, all_rodeo, by = c("year","month","day","hour","timestamp","stationid"))

return(list(new_4sw=new_4sw, new_sansimon=new_sansimon, new_rodeo=new_rodeo))
    
}

#' Appends new regional weather data
#'
#'
#'
#' @example append_regional_weather()

append_regional_weather <- function() {
  
  data <- get_regional_weather()
  
  # append new data
  write.table(data$new_4sw, file = "Weather/Portal4sw_regional_weather.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")
  
  write.table(data$new_sansimon, file = "Weather/Sansimon_regional_weather.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")
  
  write.table(data$new_rodeo, file = "Weather/Rodeo_regional_weather.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, 
              sep = ",", quote=c(5:7))
  
}
