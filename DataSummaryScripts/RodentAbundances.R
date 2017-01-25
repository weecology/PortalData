#A function to summarize monthly species abundance
#with options to summarize by "Plot", "Treatment", or "Site" (level)
#to use all plots or only plots that have had the same treatment over the entire time series
#length="Longterm"
#and to include all "Rodents" or only "Granivores" (type)

library(dplyr)
library(tidyr)

abundance <- function(level,type,length) {

rodents=read.csv('~/PortalData/Rodents/Portal_rodent.csv', na.strings=c(""), colClasses=c('tag'='character'), stringsAsFactors = FALSE)
species=read.csv('~/PortalData/Rodents/Portal_rodent_species.csv',na.strings=c(""))
plots=read.csv('~/PortalData/SiteandMethods/Portal_plots.csv')
colnames(species)[1]="species"
  

# Data cleanup

#Remove suspect trapping periods
rodents=rodents[rodents$period>0,]

#Remove unknown plots
rodents=rodents[!is.na(rodents$plot),]

# Remove bad species IDs, non-target animals
rodents = rodents %>%
  left_join(species,rodents, by="species") %>%
  filter(Rodent==1, Unidentified==0)

###########Use only Long-term treatments --------------
if(length %in% c("Longterm","longterm")) {rodents = rodents %>% filter(plot %in% c(3,4,6,10,11,14,15,16,17))}

###########Summarise by Treatment ----------------------
if(level %in% c("Treatment","treatment")){
#Name plot treatments in each time period

rodents = left_join(rodents,plots)
  
abundances = rodents %>% 
  mutate(species = factor(species)) %>% 
  group_by(period,treatment) %>%
  do(data.frame(x = table(.$species))) %>% 
  spread(x.Var1, x.Freq) %>%
  ungroup()
}

##########Summarise by plot -----------------
if(level %in% c("Plot","plot")){

  abundances = rodents %>% 
  mutate(species = factor(species)) %>% 
  group_by(period,plot) %>%
  do(data.frame(x = table(.$species))) %>% 
  spread(x.Var1, x.Freq) %>%
  ungroup()
}

##########Summarise site-wide -----------------
if(level %in% c("Site","site")){

  abundances = rodents %>% 
  mutate(species = factor(species)) %>% 
  group_by(period) %>%
  do(data.frame(x = table(.$species))) %>% 
  spread(x.Var1, x.Freq) %>%
  ungroup()
}

###########Exclude non-granivores---------------
if(type %in% c("Granivores","granivores")){
  rodents = rodents %>%
    left_join(species,rodents, by="species") %>%
    filter(Granivore==1)
}


return(abundances)
}
