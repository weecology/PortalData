# some code to match new moon dates to period sampling dates
# new moon dates downloaded from http://www.somacon.com/p570.php
# EMC 1/18/17

library(dplyr)

#setwd('C:/Users/EC/Desktop/git')


# read file of rodent census periods and dates
trappingdat = read.csv('./PortalData/Rodents/Portal_rodent_trapping.csv')   
trappingdat$CensusDate = as.Date(paste(trappingdat$Year,trappingdat$Month,trappingdat$Day,sep='-'))


# Create data frame of period numbers and date of first trapping night
census_dates = c()
for (p in unique(trappingdat$Period)) {
  perioddate <- trappingdat %>% filter(Period==p) %>% filter(CensusDate == min(CensusDate)) %>% head(1) %>% select(Period,CensusDate)
  census_dates = rbind(census_dates,perioddate)
}


# read file of moon data
moondat = read.csv('C:/Users/EC/Dropbox/Portal/PORTAL_primary_data/Rodent/Documents/moon-phases-1977-2018-America_Phoenix.csv',stringsAsFactors = F)
# date in format R understands
moondat$NewMoonDate = as.Date(moondat$date,format='%m/%d/%Y')
# extract new moons
newmoon = filter(moondat,phaseid==1) %>% select(NewMoonDate)
# create index of number of new moons since july 1977
newmoon$NewMoonNumber = seq(1,length(newmoon$NewMoonDate))


# loop through CensusDate and match each to closest NewMoonDate
newmoon$Period = rep(NA)
for (ind in seq(length(census_dates$CensusDate))) {
  closest = which.min(abs(census_dates$CensusDate[ind]-newmoon$NewMoonDate))
  newmoon$Period[closest] = census_dates$Period[ind]
}

# merge into one big data frame
moon_dates = merge(newmoon,census_dates,all.x=T,by=('Period')) %>% arrange(NewMoonDate) %>% select(NewMoonNumber,NewMoonDate, Period, CensusDate)
  

# ============================================================================================================
# write to csv
write.csv(moon_dates,file='PortalData/Rodents/moon_dates.csv',row.names=F)
