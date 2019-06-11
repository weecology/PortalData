# This script takes a raw .dat file downloaded directly from the Portal weather 
# station, determines if there are any gaps, and appends the new data to the
# weather overlap file.
# Met445.dat can be used for testing - it has a lot of problems

`%>%` <- magrittr::`%>%`

# ==============================================================================
# Load file
# ==============================================================================

# Open raw .dat file of new data
filepath = "~/Dropbox/Portal/PORTAL_primary_data/Weather/Raw_data/2002_Station/"

metfile = "Met486"

rawdata = read.csv(paste(filepath,metfile,'.dat',sep=''),head=F,sep=',',
                   col.names=c('code','year','jday','hour','precipitation','airtemp','RH'))

# Convert Julian day to month and day
rawdata$date = as.Date(paste(rawdata$year,rawdata$jday),format='%Y %j')
rawdata$month = as.integer(format(rawdata$date,'%m'))
rawdata$day = as.integer(format(rawdata$date,'%d'))
rawdata$timestamp = lubridate::ymd_hms(paste(rawdata$year,"-",rawdata$month,"-",rawdata$day," ",
                                             rawdata$hour/100,":00:00",sep=""))

# Select weather data (Code=101) from battery status data (Code=102) then add battery data as column
weathdat = rawdata[rawdata$code==101,]
battery= rawdata[rawdata$code==102,] %>% dplyr::select(year,month,day,hour,battv=precipitation)
weathdat=dplyr::left_join(weathdat,battery,by=c("year","month","day","hour"))

# Make precipitation correction 
# calculate mL from current reading (with what the datalogger *thinks*): 
# 4.73 mL/tip *(weathdat$precipitation mm / .1 mm/tip)
# then calculate mm based on actual funnel on gauge: 
# .254 mm/tip * calculated mL / 8.25 mL/tip
weathdat$precipitation=4.73*(.254*weathdat$precipitation/.1)/8.25

# ==============================================================================
# Quality control
# ==============================================================================

# check for errors in hour (should be 100,200,300,...)
if (any(!(weathdat$hour %in% seq(from=100,to=2400,by=100)))) {
  print('Hour error')
  weathdat = filter(weathdat,hour %in% seq(100,2400,100))
} else {print('Hour ok')}

# check for errors in air temp (i.e. temp > 100C or < -30)
if (any(weathdat$airtemp > 100)) {
  print('Air temp error')
  weathdat = filter(weathdat,airtemp < 100)
}
if (any(weathdat$airtemp < -30)) {
    print('Air temp error')
    weathdat = filter(weathdat,airtemp > -30)
} else {print('Air temp ok')}

# check for errors in rel humidity (either > 100 or < 0)
if (any(weathdat$RH >100)) {
  print('RelHumid error')
  weathdat = filter(weathdat,RH < 100)
} 
if (any(weathdat$RH < 0)) {
  print('RelHumid error')
  weathdat = filter(weathdat,RH > 0)
} else {print('RelHumid ok')}

# check battery status (should be ~12.5)
if (any(weathdat$battv < 11,na.rm=T)) {print('Battery error')} else {print('Battery ok')}

# check that start of new data lines up with end of existing data
exst_dat = read.csv('~/PortalData/Weather/Portal_weather_overlap.csv')
exst_dat$timestamp = lubridate::ymd_hms(exst_dat$timestamp)
first = head(exst_dat$timestamp[rowSums(is.na(exst_dat[,11:15]))==5][-(1:894)],n=1)
last = tail(exst_dat$timestamp[rowSums(is.na(exst_dat[,11:15]))==5],n=1)

if (lubridate::ymd_hms(first) %in% lubridate::ymd_hms(weathdat$timestamp)) {
  print('dates match, trimming data to match')
  
  weathdat = subset(weathdat,lubridate::ymd_hms(timestamp) >= lubridate::ymd_hms(first)) %>% 
             subset(lubridate::ymd_hms(timestamp) <= lubridate::ymd_hms(last))
  
} else {print('dates do not match')
  print('Looking for data after')
  print(first)
  }

#Add RECORD column
weathdat$record2=max(exst_dat$record2,na.rm=TRUE)+1:dim(weathdat)[1]

# plot data to look for outliers/weirdness
plot(weathdat$airtemp,type='l')
plot(weathdat$precipitation)
plot(weathdat$RH,type='l')

# ==============================================================================
# Append new data to file
# ==============================================================================

# get new data columns in correct order
newdata = dplyr::select(weathdat,c(year,month,day,hour,timestamp,record2,battv2=battv,
                                   airtemp2=airtemp,precipitation2=precipitation,RH2=RH))

overlap = exst_dat %>% 
          dplyr::full_join(newdata,by = c("year", "month", "day", "hour", "timestamp")) %>% 
          dplyr::mutate(record2 = dplyr::coalesce(record2.x, record2.y),
                 battv2 = dplyr::coalesce(battv2.x, battv2.y),
                 airtemp2 = dplyr::coalesce(airtemp2.x, airtemp2.y),
                 precipitation2 = dplyr::coalesce(precipitation2.x, precipitation2.y),
                 RH2 = dplyr::coalesce(RH2.x, RH2.y)) %>% 
          dplyr::select(colnames(exst_dat))

if(any(dim(overlap) != dim(exst_dat))) {
  print("Overlap table dimensions have changed, error in merge, 
        or you need to add data from 2016 station")
}

# write new data
write.table(overlap, file = "~/PortalData/Weather/Portal_weather_overlap.csv", 
            row.names = F, col.names = T, na = "", sep = ",")
