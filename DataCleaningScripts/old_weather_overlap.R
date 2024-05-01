# This script takes a raw .dat file downloaded directly from the Portal weather 
# station, determines if there are any gaps, and appends the new data to the
# weather overlap file.
# Met445.dat can be used for testing - it has a lot of problems

source("DataCleaningScripts/new_weather_data.r")

# ==============================================================================
# Load file
# ==============================================================================

# Open raw .dat file of new data
filepath = "~/Dropbox (UFL)/Portal/PORTAL_primary_data/Weather/Raw_data/2002_Station/"

metfile <- "Met526"

rawdata <- read.csv(paste(filepath,metfile,'.dat',sep=''),head=F,sep=',',
                   col.names=c('code','year','jday','hour','precipitation','airtemp','RH'))
if(is.na(rawdata$code[1]) | rawdata$jday[1]==0) { rawdata <- rawdata[-1,] } #if first row blank

# Convert Julian day to month and day
rawdata$date <- as.Date(paste(rawdata$year,rawdata$jday),format='%Y %j')
rawdata$month <- as.integer(format(rawdata$date,'%m'))
rawdata$day <- as.integer(format(rawdata$date,'%d'))
rawdata$timestamp <- lubridate::ymd_hms(paste(rawdata$year,"-",rawdata$month,"-",rawdata$day," ",
                                             rawdata$hour/100,":00:00",sep=""))

# Select weather data (Code=101) from battery status data (Code=102) 
# then add battery data as column
weathdat <- rawdata[rawdata$code==101,]
battery <- rawdata[rawdata$code==102,] %>% dplyr::select(year,month,day,hour,battv=precipitation)
weathdat <- dplyr::left_join(weathdat,battery,by=c("year","month","day","hour"))

# Make precipitation correction 
# calculate mL from current reading (with what the datalogger *thinks*): 
# 4.73 mL/tip *(weathdat$precipitation mm / .1 mm/tip)
# then calculate mm based on actual funnel on gauge: 
# .254 mm/tip * calculated mL / 8.25 mL/tip
weathdat$precipitation <- 4.73*(.254*weathdat$precipitation/.1)/8.25

# ==============================================================================
# Quality control
# ==============================================================================

# check for errors in hour (should be 100,200,300,...)
if (any(!(weathdat$hour %in% seq(from=100,to=2400,by=100)))) {
  print('Hour error')
  weathdat <- filter(weathdat,hour %in% seq(100,2400,100))
} else {print('Hour ok')}

# check for errors in air temp (i.e. temp > 50C or < -20)
if (any(weathdat$airtemp > 50)) {
  print('Air temp error')
  weathdat <- filter(weathdat,airtemp < 50)
}
if (any(weathdat$airtemp < -20)) {
    print('Air temp error')
    weathdat <- filter(weathdat,airtemp > -20)
} else {print('Air temp ok')}

# check for errors in rel humidity (either > 100 or < 0)
if (any(weathdat$RH >100)) {
  print('RelHumid error')
  weathdat <- filter(weathdat,RH < 100)
} 
if (any(weathdat$RH < 0)) {
  print('RelHumid error')
  weathdat <- filter(weathdat,RH > 0)
} else {print('RelHumid ok')}

# check battery status (should be ~12.5)
if (any(weathdat$battv < 11,na.rm=T)) {print('Battery error')} else {print('Battery ok')}

# plot data to look for outliers/weirdness
plot(weathdat$airtemp,type='l')
plot(weathdat$precipitation)
plot(weathdat$RH,type='l')

# ==============================================================================
# Append new data to file
# ==============================================================================

# organize new data to match overlap table format
exst_dat <- read.csv('~/PortalData/Weather/Portal_weather_overlap.csv')
exst_dat$timestamp <- lubridate::ymd_hms(exst_dat$timestamp)
newdata <- weathdat %>%
           dplyr::left_join(exst_dat[,c(1:5,11)], by = dplyr::join_by(year, hour, month, day, timestamp))
# add record numbers
if(all(is.na(newdata$record2))) {
  newdata$record2 <- 
    seq(from = max(exst_dat$record2, na.rm=TRUE) + 1 , by = 1, 
        length.out = length(newdata$record2))   
} else { 
  newdata$record2[(which.max(newdata$record2)+1):length(newdata$record2)] <- 
    seq(from = max(newdata$record2, na.rm=TRUE) + 1 , by = 1, 
        length.out = length(newdata$record2[-c(1:which.max(newdata$record2))]))
  }

newdata <- newdata %>% dplyr::mutate(battv2=battv, airtemp2=airtemp, precipitation2=precipitation, 
                                      RH2=RH, record = NA, battv=NA, airtemp=NA, precipitation=NA, 
                                      RH=NA) %>%
                        dplyr::select(c(year, month, day, hour, timestamp, record, battv,
                                        airtemp, precipitation, RH, record2, battv2,
                                        airtemp2, precipitation2, RH2)) 

overlap <- suppressMessages(coalesce_join(exst_dat, newdata, 
                                          by = c("year", "month", "day", "hour", "timestamp")))


if(any(dim(overlap) != dim(exst_dat))) {
  print("Overlap table dimensions have changed, error in merge, 
        or you need to add data from 2016 station")
}

# write new data
overlap$timestamp <- as.character(format(overlap$timestamp))
write.table(overlap, file = "~/PortalData/Weather/Portal_weather_overlap.csv", 
            row.names = FALSE, col.names = TRUE, na = "", sep = ",")
