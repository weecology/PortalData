create_df = function(dat) {
  
  #convert 'age' column to Adult/Juvenile
  dat$lifestage = ifelse(dat$age=='J','Juvenile','Adult')
  
  #convert 'note5' column to alive/dead
  dat$disposition = ifelse(dat$note5=='D','Dead','Released Alive')
  
  #convert date to yyyy-mm-dd format
  date_info = with(dat,paste(year,month,day,sep='-'))
  dates = as.Date(date_info)
  
  dataframe = data.frame(species = dat$species,
                         dates,
                         sex = dat$sex,
                         lifestage = dat$lifestage,
                         disposition = dat$disposition)
  
  return(dataframe)
}

create_permit_frame = function(new_df) {
  #convert 2 letter species code to scientific name and common name
  spdata = read.csv("Rodents/Portal_rodent_species.csv", head = T, sep = ',', na.strings = "", as.is=T)
  new_df = merge(new_df,spdata,by.x='name',by.y='speciescode')
  
  # convert Tag to PIT if animal was released alive, blank if dead
  new_df$Tag = ifelse(new_df$disposition == 'Released Alive','PIT','')
  
  #convert M/F to Male/Female
  new_df$sex = as.character(new_df$sex)
  new_df$sex[new_df$sex == 'M'] = 'Male'
  new_df$sex[new_df$sex == 'F'] = 'Female'
  new_df$sex[new_df$sex == ''] = 'na'
  
  outframe = data.frame(ScientificName = new_df$scientificname,
                        CommonName = new_df$commonname,
                        x = new_df$x,
                        dates = new_df$dates,
                        county = rep('Cochise',length(new_df$sex)),
                        waterbody = rep('',length(new_df$sex)),
                        easting = rep(681200.79,length(new_df$sex)),
                        northing = rep(3535287.25,length(new_df$sex)),
                        UTMZone = rep('12S',length(new_df$sex)),
                        datum = rep('',length(new_df$sex)),
                        lifestage = new_df$lifestage,
                        sex = new_df$sex,
                        disposition = new_df$disposition,
                        museum = rep('',length(new_df$sex)),
                        tag = new_df$Tag,
                        fieldtag = rep('',length(new_df$sex)),
                        habitat = rep('desert scrubland',length(new_df$sex)),
                        other = rep('',length(new_df$sex)),
                        comments = rep('',length(new_df$sex)))
  return(outframe) 
}
# ============================================================================

datafile = "Rodents/Portal_rodent.csv"
year = 2018
#read in raw data
rawdata = read.csv(datafile,head=T,sep=',',na.strings=' ',as.is=T)

thisyear = rawdata[rawdata$year == year,]

dataframe = create_df(thisyear)

data_agg = aggregate(dataframe$species,list(name=dataframe$species, dates=dataframe$dates, sex=dataframe$sex, lifestage=dataframe$lifestage, disposition=dataframe$disposition),FUN=length)

outframe = create_permit_frame(data_agg)

outfile = paste0('Reports/Permit_data_', year, '.csv')
write.csv(outframe,file=outfile,row.names=F)
