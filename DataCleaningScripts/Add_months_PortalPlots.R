#' Appends new dates to Portal_plots
#'
#'
#' 
#' @example update_portal_plots()
#' 
#'
#'
library(zoo)
update_portal_plots <- function() {
#load plot data
portal_plots = read.csv("../SiteandMethods/Portal_plots.csv")
# load rodent data
rodentdat = read.csv("../Rodents/Portal_rodent.csv",stringsAsFactors = F,as.is=T,na.strings = '')  

# define currrent plot treatments

controls = c(4,5,6,7,11,13,14,17,18,24)
removals = c(1,9,10,12,16,23)
exclosures = c(2,3,8,15,19,20,21,22)

# proceed only if rodentdat has more recent data than plot data
lastplotdates=max(as.yearmon(paste(substr(portal_plots$yr,3,4),portal_plots$month), "%y%m"))
newdates=max(as.yearmon(paste(substr(rodentdat$yr,3,4),rodentdat$mo), "%y%m"))

if (newdates > 
    lastplotdates) {
  
  yr = rep(year(newdates),24)
  month = rep(month(newdates),24)
  plot = 1:24
  
  newplots = data.frame(cbind(yr,month,plot,treatment=NA))
  
  newplots = newplots %>% mutate(treatment = ifelse((plot %in% removals),
                                                                    "removal", treatment)) %>% 
    mutate(treatment = ifelse((plot %in% exclosures),"exclosure", treatment)) %>% 
    mutate(treatment = ifelse((plot %in% controls),"control", treatment))
  
  portal_plots = bind_rows(portal_plots,newplots)
}

return(portal_plots)
}

#Write new portal plot file
writeportalplots <- function(portal_plots) {
  write.csv(portal_plots, file='../SiteandMethods/Portal_plots.csv',row.names = F)
}

###################################
###This is hw the original Portal_plots.csv was created 
###Code to take the original Portal_plots.csv which only reported plot treatment by year
### And add in what month is was in what treatment
### This allows us to more finely control summarizing the Portal data
### by being able assign exactly when a plot changed treatment
### Info for what month a treatment changed was obtained from:
### 
###################################
library(dplyr)


data = read.csv("../PortalData/SiteandMethods/Portal_plots.csv")
unique_Years = unique(data$yr)
unique_Plots = unique(data$plot)

yr = rep(unique_Years, times = 12*length(unique_Plots))
yr = sort(yr)
month = rep(1:12, times = length(unique_Years)*length(unique_Plots))
plot = rep(1:24, times = 12*length(unique_Years))
new_Portal_plots = data.frame(yr,month)
new_Portal_plots  = new_Portal_plots[order(month),]
new_Portal_plots = cbind(new_Portal_plots, plot)

# sets plots to the main treatment they spend the most time in
new_Portal_plots = new_Portal_plots %>% mutate(treatment = 
                                                 ifelse(plot %in% c(3,15,19,21), 
                                                        'exclosure', 
                                                        ifelse(plot %in% c(5,7,10,16,23,24),
                                                               'removal', 'control')))

############################## adds the spectab treatments. 
#
# Plots 5 & 24 started as spectab removals and were switched to removals 1/1/1989 (Brown 1989)
# Plots 1 & 9 started as controls and switched to spectab removals 1/1/1989 (Brown 1989) &
#             switched back in 2004 (exact date currently unknown)
##############################

new_Portal_plots = new_Portal_plots %>% mutate(date = as.Date(paste(yr,"-",month, "-", 1, sep=""),
                                                              format="%Y-%m-%d"))
new_Portal_plots = new_Portal_plots %>% mutate(treatment = ifelse((plot ==1 | plot ==9) & 
                                             (date < '2005-1-1' & date > '1987-12-1'),
                                             "spectabs", treatment))
new_Portal_plots = new_Portal_plots %>% mutate(treatment = ifelse((plot ==5 | plot ==24) & 
                                              (date < '2005-1-1' & date > '1987-12-1'),
                                            "spectabs", treatment))

############################## adds the regime flips 
#
# All plots were switched after rodent census in March 2015. 1st treatment month April 2015
# Plots 1,9,12 switched from controls to removals. 
# Plots 2,8,22 switched from controls to exclosures
# Plots 5,7,24 switched from removals to controls
# Plots 6,13,18 switched from exclosures to controls
##############################

new_Portal_plots = new_Portal_plots %>% mutate(treatment = ifelse((plot %in% c(1,9,12)) & 
                                                                    date > '2015-3-1',
                                                                  "removal", treatment))
new_Portal_plots = new_Portal_plots %>% mutate(treatment = ifelse((plot %in% c(2,8,22)) & 
                                                                    date > '2015-3-1',
                                                                  "exclosure", treatment))
new_Portal_plots = new_Portal_plots %>% mutate(treatment = ifelse((plot %in% c(5,6,7,13,18,24)) & 
                                                                    date > '2015-3-1',
                                                                  "control", treatment))

############################# adds the 1989-2015 (nonspectab) treatment changes
# 
# Plots 6,13,18,20, added to krat removal on January 1989 (Brown 1989)
#############################

new_Portal_plots = new_Portal_plots %>% mutate(treatment = ifelse((plot %in% c(6,13,18,20)) & (date < '2015-4-1' & date > '1987-12-1'),
                                                                  "exclosure", treatment))

############################# changes all plots to control for 1st 3 months of study
# 
# For the 1st 3 months (july, august, september) all plots were controls.
# Treatments started october 1977 (Brown 1998)
#############################


new_Portal_plots = new_Portal_plots %>% mutate(treatment = ifelse(date < '1977-10-1',
                                                                  "control", treatment))
############################# remove entries before plots existed
# Current code creates plot table starting January 1977 for all plots but
#      trapping did not start until July 1977 (Brown 1998)
# And plot 24 didn't exist until August 1979 (Portal_rodent.csv)
#############################

new_Portal_plots = new_Portal_plots %>% filter(date >  "1977-06-1")
new_Portal_plots = new_Portal_plots[!(new_Portal_plots$date <"1979-08-01" &
                                         new_Portal_plots$plot==24),]

############################ Create file
write.csv(new_Portal_plots, file='../PortalData/SiteandMethods/new_Portal_plots.csv')




