# Get longer stretches of Wunderground data
stationids <- c("KAZSANSI26","KNMRODEO11","KAZPORTA10","KNMRODEO8","KNMANIMA10","KNMANIMA15")
stationid <- "KNMRODEO8"
  
for(i in as.Date(as.Date("2023-01-01"):Sys.Date(), origin = "1970-01-01")) {

i = gsub("-","",as.Date(i, origin = "1970-01-01"))
rustys <- jsonlite::fromJSON(
  paste('https://api.weather.com/v2/pws/history/hourly?stationId=',stationid,'&format=json&units=m&date=',i,'&apiKey=',Sys.getenv("WU_API_KEY"), sep=""))$observations
rustys <- dplyr::bind_cols(rustys[,1:14], rustys$metric) %>%
  dplyr::rename_all(.funs = tolower) %>%
  dplyr::select(-epoch,-obstimeutc) %>%
  dplyr::rename(timestamp = obstimelocal, latitude = lat, longitude = lon) %>%
  dplyr::mutate_all(as.character) %>% 
  dplyr::mutate_at(tail(names(.), 32), as.numeric) %>%
  dplyr::mutate(timestamp = round(lubridate::ymd_hms(timestamp), units="hours")) %>%
  dplyr::mutate(day = lubridate::day(timestamp), 
                month = lubridate::month(timestamp), 
                year = lubridate::year(timestamp),
                hour = lubridate::hour(timestamp)) %>%
  dplyr::select(year, month, day, hour, dplyr::everything())

#Fix hour and day so midnight=2400
rustys$hour[rustys$hour==0] = 24 ; rustys$hour = 100*rustys$hour
rustys$day[rustys$hour==2400] = rustys$day[which(rustys$hour==2400)-1]
rustys$month[rustys$hour==2400] = rustys$month[which(rustys$hour==2400)-1]
rustys$year[rustys$hour==2400] = rustys$year[which(rustys$hour==2400)-1]

rustys_all = dplyr::bind_rows(rustys_all,rustys)
}

rodeo_all = rustys_all
rodeo_all = rodeo_all %>%
  dplyr::select("year","month","day","hour","timestamp","stationid","tz","latitude",
                "longitude","solarradiationhigh","uvhigh","winddiravg", "humidityhigh",
                "humiditylow","humidityavg","qcstatus", "temphigh", "templow", "tempavg",
                "windspeedhigh", "windspeedlow", "windspeedavg", "windgusthigh", 
                "windgustlow", "windgustavg", "dewpthigh", "dewptlow", "dewptavg",
                "windchillhigh", "windchilllow", "windchillavg", "heatindexhigh", 
                "heatindexlow", "heatindexavg", "pressuremax", "pressuremin", 
                "pressuretrend", "preciprate", "preciptotal")

write.table(rodeo_all, file = "Weather/Rodeo_regional_weather.csv",
            row.names = FALSE, col.names = FALSE, append=TRUE, na = "", sep = ",", quote=c(5:7))
