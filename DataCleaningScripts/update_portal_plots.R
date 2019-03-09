library(zoo)
library(dplyr)

#' Appends new dates to Portal_plots
#'
#'
#' 
#' @example update_portal_plots()
#' 
#'
#'


update_portal_plots <- function() {
  #load plot data
  portal_plots = read.csv("SiteandMethods/Portal_plots.csv",stringsAsFactors = FALSE)
  # load rodent data
  rodentdat = read.csv("Rodents/Portal_rodent.csv",stringsAsFactors = FALSE,as.is=TRUE,na.strings = '')  
  
  # define currrent plot treatments
  
  controls = c(4,5,6,7,11,13,14,17,18,24)
  removals = c(1,9,10,12,16,23)
  exclosures = c(2,3,8,15,19,20,21,22)
  
  # proceed only if rodentdat has more recent data than plot data
  #find new rows
  newrows=which(paste(rodentdat$year,rodentdat$month) %in% paste(portal_plots$year,portal_plots$month)
                  ==FALSE)
  newdat = unique(na.omit(rodentdat[newrows,c(2,4)])) 
  
  if (nrow(newdat)>0) {
    
    plot=1:24
    newplots=merge(newdat,plot,by=NULL) %>% rename(plot=y) %>% arrange(year,month,plot) 
    
    newplots$treatment = NA
    
    newplots = newplots %>% mutate(treatment = ifelse((plot %in% removals),
                                                      "removal", treatment)) %>% 
      mutate(treatment = ifelse((plot %in% exclosures),"exclosure", treatment)) %>% 
      mutate(treatment = ifelse((plot %in% controls),"control", treatment))
    
    portal_plots = bind_rows(portal_plots,newplots)
  }
  
  return(portal_plots)
}

#' Rewrites file Portal_plots.csv with latest trapping dates
#'
#'
#' 
#' @example writeportalplots()
#' 
#'
#'
writeportalplots <- function() {
  portal_plots = update_portal_plots()
  write.csv(portal_plots, file='SiteandMethods/Portal_plots.csv', row.names = FALSE, quote = FALSE)
}
