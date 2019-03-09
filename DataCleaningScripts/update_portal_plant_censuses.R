# This creates the Portal_plant_censuses.csv file in the Plants folder
# Record of which quadrats were or were not counted in each census and exact dates
# **This assumes all quadrats were censused in each season listed in the data**
# If a quadrat is flagged as missing in the data cleaning process, 
# you must manually change it's value to zero
# If a season gets skipped entirely, it should also be manually added

library(dplyr)

#' Appends new census dates to Portal_plant_censuses
#'
#'
#' 
#' @example update_portal_plant_censuses()
#' 
#'
#'

update_portal_plant_censuses = function() {
  # load quadrat data
  plantdat = read.csv("Plants/Portal_plant_quadrats.csv",stringsAsFactors = FALSE,as.is=TRUE,na.strings = '')  
  # load rodent trapping data
  censuses=read.csv("Plants/Portal_plant_censuses.csv",stringsAsFactors = FALSE)  
  
  # proceed only if plantdat has more recent data than censuses
  
  #find new rows
  newdat = unique(anti_join(plantdat[,1:3],censuses[,1:3], by = c("year", "season", "plot")))
  
  if (nrow(newdat) != 0) {
    
    # extract quadrat data beyond what's already in censuses
    quadrats = c(11,13,15,17,31,33,35,37,51,53,55,57,71,73,75,77)
    newdat = merge(newdat,quadrats) %>% rename(quadrat=y) %>% arrange(year,desc(season),plot,quadrat) 
    newdat$censused = 1
    newdat$area = 0.25

    # append to censuses
    censuses = rbind(censuses,newdat)
  }
  return(censuses)
}

#' Rewrites file Portal_plant_censuses.csv with latest census info
#'
#'
#' 
#' @example writecensustable()
#' 
#'
#'
writecensustable <- function() {
  
  censuses=update_portal_plant_censuses()
  # write updated data frame to csv
  write.csv(censuses, file="Plants/Portal_plant_censuses.csv", row.names=FALSE, quote = FALSE) }
