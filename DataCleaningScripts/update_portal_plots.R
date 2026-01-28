library(zoo, warn.conflicts=FALSE, quietly = TRUE)
library(dplyr, warn.conflicts=FALSE, quietly = TRUE)

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
  rodentdat = read.csv("Rodents/Portal_rodent.csv",
                       stringsAsFactors = FALSE,as.is=TRUE,na.strings = '')  
  
  # define current plot treatments
  
  controls = c(4,5,6,7,11,13,14,17,18,24)
  removals = c(1,9,10,12,16,23)
  exclosures = c(2,3,8,15,19,20,21,22)
  
  # proceed only if rodentdat has more recent data than plot data
  # find new rows
  newrows=which(paste(rodentdat$year,rodentdat$month) %in% 
                  paste(portal_plots$year,portal_plots$month)
                  ==FALSE)
  
  if (length(newrows)>0) {
    
  latest <- unique(na.omit(rodentdat[newrows,c(2,4)])) %>%
            mutate(date = as.Date(paste(year,month,"1",sep="-")))
  current <- tail(portal_plots[,c(1,2)],1) %>%
             mutate(date = as.Date(paste(year,month,"1",sep="-")))
  newdat <- data.frame(date = as.Date(current$date:max(latest$date))) %>%
            mutate(year = lubridate::year(date),
                   month = lubridate::month(date)) %>%
            select(-date) %>%
            unique() %>%
            anti_join(current[,1:2], by = join_by(year, month))
  
  if (nrow(newdat)>0) {
    
    plot=1:24
    newplots=merge(newdat,plot,by=NULL) %>% rename(plot=y) %>% arrange(year,month,plot) 
    
    newplots$treatment = NA
    
    newplots = newplots %>% 
      mutate(treatment = ifelse((plot %in% removals),"removal", treatment)) %>% 
      mutate(treatment = ifelse((plot %in% exclosures),"exclosure", treatment)) %>% 
      mutate(treatment = ifelse((plot %in% controls),"control", treatment))
    
    portal_plots = bind_rows(portal_plots,newplots) %>% arrange(year,month,plot)

      }}
  
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
