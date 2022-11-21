library(dplyr)
library(lubridate)
library(vistime)
library(RColorBrewer)
library(ggplot2)

portal_plots = read.csv("./SiteandMethods/Portal_plots.csv",stringsAsFactors = FALSE)
portal_plots$start_date = mdy(paste(portal_plots$month,1,portal_plots$year,sep="/"),tz="GMT")
portal_plots = portal_plots %>% arrange(plot,start_date)

keepindex=1
for(i in 2:11687){
  if(all.equal(portal_plots[i,3:4],portal_plots[i-1,3:4],check.attributes=F)!=TRUE) 
  {keepindex=c(keepindex,i)}
}  

keep=portal_plots[keepindex,]
keep$end_date=c(keep$start_date[-1],Sys.Date())
keep$end_date[which(keep$start_date>keep$end_date)]=Sys.Date()
keep$end_date[keep$end_date=="1977-07-01"]=Sys.Date()
keep$end_date[keep$end_date=="1979-08-01"]=Sys.Date()

cbPalette <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7","#999999","#000000")

color.table=data.frame(treatment=c("control","removal","exclosure","spectabs"),color=cbPalette[1:4])

keep = left_join(keep,color.table)

vistime(keep, events = "treatment", groups = "plot", 
        start = "start_date", end="end_date",colors="color",
        showLabels = FALSE,
        linewidth = 12, lineInterval = 5*365*24*60*60)


#Make plot for plant treatments
portal_plots$resourcetreatment[is.na(portal_plots$resourcetreatment)]="none"
pindex=1
for(i in 2:11687){
  if(all.equal(portal_plots[i,c(3,5)],portal_plots[i-1,c(3,5)],check.attributes=F)!=TRUE) 
  {pindex=c(pindex,i)}
}  

plants=portal_plots[pindex,]
plants$end_date=c(plants$start_date[-1],Sys.Date())
plants$end_date[which(plants$start_date>plants$end_date)]=Sys.Date()

plant.color.table=data.frame(resourcetreatment=unique(plants$resourcetreatment),color=cbPalette)

plants = left_join(plants,plant.color.table,by="resourcetreatment")

vistime(plants, events = "resourcetreatment", groups = "plot", 
        start = "start_date", end="end_date",colors="color",
        showLabels = FALSE,
        linewidth = 12, lineInterval = 5*365*24*60*60)

#Make plot for ant treatments
portal_plots$anttreatment[is.na(portal_plots$anttreatment)]="none"
antindex=1
for(i in 2:11687){
  if(all.equal(portal_plots[i,c(3,6)],portal_plots[i-1,c(3,6)],check.attributes=F)!=TRUE) 
  {antindex=c(antindex,i)}
}  

ants=portal_plots[antindex,]
ants$end_date=c(ants$start_date[-1],Sys.Date())
ants$end_date[which(ants$start_date>ants$end_date)]=Sys.Date()
ants$end_date[ants$end_date=="1977-07-01"]=Sys.Date()

ant.color.table=data.frame(anttreatment=unique(ants$anttreatment),color=cbPalette[1:3])

ants = left_join(ants,ant.color.table,by="anttreatment")

vistime(ants, events = "anttreatment", groups = "plot", 
        start = "start_date", end="end_date",colors="color",
        showLabels = FALSE,
        linewidth = 12, lineInterval = 5*365*24*60*60)
