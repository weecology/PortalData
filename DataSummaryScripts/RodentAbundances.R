#A function to summarize monthly species abundance
#with options to summarize by "Plot", "Treatment", or "Site" (level)
#and to include all "Rodents" or only "Granivores" (type)

library(dtplyr)
library(dplyr)
library(tidyr)

abundance <- function(level,type) {

rodents=read.csv('~/PortalData/Rodents/Portal_rodent.csv', na.strings=c(""), colClasses=c('tag'='character'), stringsAsFactors = FALSE)
species=read.csv('~/PortalData/Rodents/Portal_rodent_species.csv',na.strings=c(""))
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


###########Summarise by Treatment ----------------------
if(level=="Treatment"){
#Name plot treatments in each time period
removal=c(2,4,8,11,12,14,17,22) #removals
exclosure=c(3,6,13,18,19,20) #krat exclosures

removal2=c(2,4,8,11,12,14,17,22) #removals post March 2015
exclosure2=c(3,6,13,18,19,20) #krat exclosures post March 2015

rodents$treatment = "control"
rodents$treatment[rodents$plot %in% removal] = "removal"
rodents$treatment[rodents$plot %in% exclosure] = "kratexclosure"


abundances = rodents %>% 
  mutate(species = factor(species)) %>% 
  group_by(period,treatment) %>%
  do(data.frame(x = table(.$species))) %>% 
  spread(x.Var1, x.Freq) %>%
  ungroup()
}

##########Summarise by plot -----------------
if(level=="Plot"){
abundances = rodents %>% 
  mutate(species = factor(species)) %>% 
  group_by(period,plot) %>%
  do(data.frame(x = table(.$species))) %>% 
  spread(x.Var1, x.Freq) %>%
  ungroup()
}

##########Summarise site-wide -----------------
if(level=="Site"){
abundances = rodents %>% 
  mutate(species = factor(species)) %>% 
  group_by(period) %>%
  do(data.frame(x = table(.$species))) %>% 
  spread(x.Var1, x.Freq) %>%
  ungroup()
}

###########Exclude non-granivores---------------
if(type=="Granivores"){
  rodents = rodents %>%
    left_join(species,rodents, by="species") %>%
    filter(Granivore==1)
}


return(abundances)
}
