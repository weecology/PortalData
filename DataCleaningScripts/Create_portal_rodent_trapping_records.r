# This script creates the Portal_rodent_trapping.csv file in the Rodents folder
# Record of which plots were or were not trapped in each census and exact dates

# EMC 5/2016

library(sqldf)

# setwd('C:/Users/EC/Desktop/git/PortalData')

# load rodent trapping data
rodentdat = read.csv('../Rodents/Portal_rodent.csv',as.is=T,na.strings = '')

# select date, period, plot columns
plotdat = sqldf("SELECT mo, dy, yr, period, plot, note1
       FROM rodentdat
        WHERE ((rodentdat.period > 0)
        AND (rodentdat.plot Is NOT NULL))
                ORDER BY period, plot;")

# put rows in order of period, plot
plotdat1 = plotdat[order(plotdat$period,plotdat$plot),]

# make column for sampled/not sampled
plotdat1$Sampled = rep(1)
plotdat1$Sampled[plotdat1$note1 == 4] = 0

# create final data frame
portal_trapping = data.frame(Day = plotdat1$dy,
                             Month = plotdat1$mo,
                             Year = plotdat1$yr,
                             Period = plotdat1$period,
                             Plot = plotdat1$plot,
                             Sampled = plotdat1$Sampled)

# remove duplicate rows
portal_trapping = portal_trapping[!duplicated(portal_trapping[,c(4,5,6)]),]

# checks for periods with less than 24 plots
check = aggregate(portal_trapping$Sampled,by=list(portal_trapping$Period),FUN = length)

check[check$x != 24,]

# Periods prior to Period 26 need to be
# handled separately because only 23 plots existed

# fill in missing plots with "not trapped"
short = check$Group.1[check$x<24 && check$Group.1 > 26]

missing = c()
for (n in short) {
  period = portal_trapping[portal_trapping$Period == n,]
  for (plt in seq(24)) {
    if (!(plt %in% period$Plot)) {
      portal_trapping = rbind(portal_trapping,c(period$Day[1],period$Month[1],period$Year[1],period$Period[1],plt,0))
    }
  }
}

# put back in order
portal_trapping = portal_trapping[order(portal_trapping$Period,portal_trapping$Plot),]

# write to file
write.csv(portal_trapping,'../Rodents/Portal_rodent_trapping.csv', row.names = F)
