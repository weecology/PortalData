# clean plant quad data
# EMC 1/6/16

# Notes:
#   empty quadrats are coded as "none" for purposes of error checking, will be removed later
#   add "unkn gras" and "unkn forb" to sp list
#   add to sp list: spha sp, sita hyst, apod undu, kall cali, euph sp, bout sp, lina texa, 
#       cryp sp, laen coul, chen sp, dale sp, amsi sp, mala sp, pseu cane, hete suba, erag sp,
#       erig sp, erig conc
#   changed buoh dact to bout dact -- some ambiguity as to classification of buffalograss
#   are dates important?  people don't always write the date on the sheet
#   I deleted any data from plot 24 stake 17 (winter 2014) -- this quadrat is outside the plot
#   if there was a duplicate species count within a plot, I took the higher count
#   leaving blank abundances blank for now
#   summer 2015, plot 13, stake 35 was recorded by 2 different groups and 33 not at all.  I used the presence of large acacia in past censuses to determine that one of these was in fact stake 33
#   winter 2015, plot 12, stake 31 and 35 were recorded twice (by same group) and stake 15 and 17 not recorded. I made a best guess.  


library(stringr)
library(Hmisc)

dat1 = read.csv('C:/Users/EC/Desktop/Winter2014.csv')
dat2 = read.csv('C:/Users/EC/Desktop/Summer2014.csv')
dat3 = read.csv('C:/Users/EC/Desktop/Winter2015.csv')
dat4 = read.csv('C:/Users/EC/Desktop/Summer2015.csv')

splist = read.csv('C:/Users/EC/Desktop/Portal_plant_species_rev2015.csv',as.is=T)
plots = seq(24)
stakes = c(11,13,15,17,31,33,35,37,51,53,55,57,71,73,75,77)

# =====================================
# species names not in official list
unique(dat1$species[!(dat1$species %in% splist$Species.Code)])
unique(dat2$species[!(dat2$species %in% splist$Species.Code)])
unique(dat3$species[!(dat3$species %in% splist$Species.Code)])
unique(dat4$species[!(dat4$species %in% splist$Species.Code)])


# =====================================
# are all quadrats present

allquads = apply(expand.grid(plots,stakes),1,paste,collapse=' ')

dat = dat3
plotquad = unique(paste(dat$plot,dat$stake))
# any plot-stake pairs in the data that are not supposed to be censused
setdiff(plotquad,allquads)
# any plot-stake pairs that should be censused that are not in the data -- should see "24 17"
setdiff(allquads,plotquad)

# =====================================
# are there any duplicate entries of plot/quadrat/species

dat = dat3
dat[(duplicated(paste(dat$plot,dat$stake,dat$species))),]


# =====================================
# are there any plants recorded in the same quadrat as a "none"

dat = dat3
nones = dat[dat$species == 'none',]
dat[(paste(dat$plot,dat$stake) %in% paste(nones$plot,nones$stake)),]

# ====================================
# any empty data cells

dat = dat3
dat[is.na(dat$abundance),]
dat[is.na(dat$species),]

# =====================================
# save cleaned up version

dat1clean = dat1[dat1$species != 'none',]
dat2clean = dat2[dat2$species != 'none',]
dat3clean = dat3[dat3$species != 'none',]
dat4clean = dat4[dat4$species != 'none',]

write.csv(dat1clean,file='C:/Users/EC/Desktop/Winter2014_clean.csv',row.names=F)
write.csv(dat2clean,file='C:/Users/EC/Desktop/Summer2014_clean.csv',row.names=F)
write.csv(dat3clean,file='C:/Users/EC/Desktop/Winter2015_clean.csv',row.names=F)
write.csv(dat4clean,file='C:/Users/EC/Desktop/Summer2015_clean.csv',row.names=F)
