# title: "EML for Streaming Data"
# author: "Anna Liu"
# date: "October 5, 2016"

#devtools::install_github("ropensci/EML")
library(EML)
library(RCurl)

## Data tables
# Ants

# read files 
ant_bait = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Ants/Portal_ant_bait.csv")
Encoding(ant_bait) = "latin1"
ant_bait = iconv(ant_bait, "latin1", "UTF-8", sub="")

ant_colony = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Ants/Portal_ant_colony.csv")
Encoding(ant_colony) = "latin1"
ant_colony = iconv(ant_colony, "latin1", "UTF-8", sub="")

ant_dataflags = read.csv("https://raw.githubusercontent.com/weecology/PortalData/master/Ants/Portal_ant_dataflags.csv")
ant_dataflags = as.data.frame(sapply(ant_dataflags, function(x){
  x = as.character(x)
  Encoding(x) = "latin1"
  iconv(x, "latin1", "UTF-8", sub="")
}))

ant_species = read.csv("https://raw.githubusercontent.com/weecology/PortalData/master/Ants/Portal_ant_species.csv")
ant_species = as.data.frame(sapply(ant_species, function(x){
  x = as.character(x)
  Encoding(x) = "latin1"
  iconv(x, "latin1", "UTF-8", sub="")
}))

# eml for bait
ant_bait_attributes = data.frame(
  attributeName=c("Month","Year","Plot","Stake","Species","Abundance"), 
  formatString=c(NA,"YYYY",NA,NA,NA,NA), 
  definition=c("July",NA,"plot number","stake number","species name","Number of individuals"), 
  unit=c("dimensionless","nominalYear","number",
         "number","dimensionless","number"),
  attributeDefinition=c("July of each year",
                        "Year. Range: 1977-2009",
                        "Plot number. Range: 1-24",
                        "Stake number on each plot. Range: 1-49",
                        "Species name (string)",
                        "Number of individuals of a certain species within the 10 cm diameter bait circle"),
  numberType=c(NA,NA,"integer","integer",NA,"integer"),
  stringsAsFactors=FALSE)

attributeList_bait = set_attributes(ant_bait_attributes, col_classes = c("character", "Date", "numeric","numeric","character","numeric"))

physical_bait = set_physical(ant_bait)

geographicDescription = "Study of a Chihuahuan desert ecosystem near Portal, AZ began in 1977. The site occurs in an upper-elevation Chihuahuan Desert habitat (1330 m), dominated by a mixture of shrubs (e.g. Flourensia cernua, Acacia sp., Prosopis sp.) and grasses (e.g. Aristida sp. Bouteloua sp., Muhlenbergia porteri.). Dominance of grasses versus shrubs has shifted over the 30 years of the study, shifting from what was mainly a desertified open grassland to a mixed shrubland (Brown et al 1997). The site itself sits on a bajada at the base of the Chiricahua Mountains and consists of mainly sandy soils."

coverage_ant =  
  set_coverage(begin = '1988-07-01', end = '2009-07-31',
               sci_names = as.character(ant_species$Scientific.Name),
               geographicDescription = geographicDescription,
               west = -109.079844, east = -109.079844, 
               north = 31.938969, south = 31.938969)

dataTable_bait = new("dataTable",
                     entityName = "Portal_ant_bait.csv",
                     entityDescription = "Bait Census",
                     physical = physical_bait,
                     attributeList = attributeList_bait,
                     coverage=coverage_ant)

# colony
ant_colony_attributes = data.frame(
  attributeName=c("Day","Month","Year","Plot","Stake","Species","Colonies","Openings","Flag"), 
  formatString=c(NA,NA,"YYYY",NA,NA,NA,NA,NA,NA), 
  definition=c("day","month",NA,"plot number","stake number","species name","number of colonies","number of colony entrances","additional info"), 
  unit=c("nominalDay","dimensionless","nominalYear","number","number",
         "dimensionless","number","number","number"),
  attributeDefinition=c("Day",
                        "Month",
                        "Year. Range: 1977-2009",
                        "Plot number. Range: 1-24",
                        "Stake number on each plot",
                        "Species name (string)",
                        "number of colonies",
                        "number of colony entrances for all diurnal species",
                        "reference to data_flag table for additional info"),
  numberType=c(NA,NA,NA,"integer","integer",NA,
               "integer","integer","integer"),
  stringsAsFactors=FALSE)

factors_colony = data.frame(attributeName = "Flag",
                            code = ant_dataflags$Flag,
                            definition = ant_dataflags$Meaning)

attributeList_colony = set_attributes(ant_colony_attributes, factors_colony, col_classes = c("character","character","Date","numeric","numeric","character","numeric","numeric","factor"))

physical_colony = set_physical(ant_colony)

dataTable_colony = new("dataTable",
                       entityName = "Portal_ant_colony.csv",
                       entityDescription = "Colony Census",
                       physical = physical_colony,
                       attributeList = attributeList_colony,
                       coverage = coverage_ant)

# plant
plant_1981_2015 = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Plants/Portal_plant_1981_2015.csv")
Encoding(plant_1981_2015) = "latin1"
plant_1981_2015 = iconv(plant_1981_2015, "latin1", "UTF-8", sub="")

plant_2015_present = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Plants/Portal_plant_2015_present.csv")
Encoding(plant_2015_present) = "latin1"
plant_2015_present = iconv(plant_2015_present, "latin1", "UTF-8", sub="")

plant_census_dates = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Plants/Portal_plant_census_dates.csv")
Encoding(plant_census_dates) = "latin1"
plant_census_dates = iconv(plant_census_dates, "latin1", "UTF-8", sub="")

plant_censuses = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Plants/Portal_plant_censuses.csv")
Encoding(plant_censuses) = "latin1"
plant_censuses = iconv(plant_censuses, "latin1", "UTF-8", sub="")

plant_species = read.csv("https://raw.githubusercontent.com/weecology/PortalData/master/Plants/Portal_plant_species.csv")
plant_species = as.data.frame(sapply(plant_species, function(x){
  x = as.character(x)
  Encoding(x) = "latin1"
  iconv(x, "latin1", "UTF-8", sub="")
}))

plant_transects_2015_present = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Plants/Portal_plant_transects_2015_present.csv")
Encoding(plant_transects_2015_present) = "latin1"
plant_transects_2015_present = iconv(plant_transects_2015_present, "latin1", "UTF-8", sub="")

temp1 = as.character(plant_species$Species)
temp1[as.character(plant_species$Species) %in% ""] = 
  as.character(plant_species$Alt.Species)[as.character(plant_species$Species) %in% ""]
plant_sci_names = paste(as.character(plant_species$Genus), temp1, sep=" ")

coverage_plant = set_coverage(begin = '1981', end = '2016',
                              sci_names = plant_sci_names,
                              geographicDescription = geographicDescription,
                              west = -109.079844, east = -109.079844, 
                              north = 31.938969, south = 31.938969)

plant_1981_2015_attributes = data.frame(
  attributeName=c("year","season","plot","quadrat","species","abundance"), 
  formatString=c("YYYY",NA,NA,NA,NA,NA), 
  definition=c(NA,NA,"plot number","quadrat number","species name","number of individuals"), 
  unit=c("nominalYear","dimensionless","number",
         "number","dimensionless","number"),
  attributeDefinition=c("Year. Range: 1981-2015",
                        "Season: summer or winter",
                        "Plot number. Range: 1-24",
                        "Quadrat number on each plot",
                        "Species name (string)",
                        "Number of individuals of a certain species within the 10 cm diameter bait circle"),
  numberType=c(NA,NA,"integer","integer",NA,"integer"),
  stringsAsFactors=FALSE)

Season = c(summer="plant surveys are done in summer", winter="plant surveys are done in winter")
factor_plant_1981_2015 = data.frame(attributeName = "season",
                                    code = names(Season),
                                    definition = unname(Season))

attributeList_plant_1981_2015 = set_attributes(plant_1981_2015_attributes, factor_plant_1981_2015, col_classes = c("Date", "factor","numeric","numeric","character","numeric"))

physical_plant_1981_2015 = set_physical(plant_1981_2015)

dataTable_plant_1981_2015 = new("dataTable",
                                entityName = "plant_1981_2015.csv",
                                entityDescription = "Plant censuses from 1981 to 2015",
                                physical = physical_plant_1981_2015,
                                attributeList = attributeList_plant_1981_2015,
                                coverage = coverage_plant)

#=====================================================================================
plant_2015_present_attributes = data.frame(
  attributeName=c("year","season","plot","quadrat","species","abundance","cover","cf"), 
  formatString=c("YYYY",NA,NA,NA,NA,NA,NA,NA), 
  definition=c(NA,"season","plot number","quadrat number",
               "species name","number of individual",
               "coverage percentage","cf"), 
  unit=c("nominalYear","dimensionless","number","number",
         "dimensionless","number","number","dimensionless"),
  attributeDefinition=c("Year",
                        "Season: summer or winter",
                        "Plot number. Range: 1-24",
                        "Quadrat number on each plot",
                        "Species name (string)",
                        "Number of individuals of a certain species within the 10 cm diameter bait circle",
                        "% covered for each species",
                        "cf"),
  numberType=c(NA,NA,"integer","integer",NA,"integer","integer",NA),
  stringsAsFactors=FALSE)

Season = c(summer="plant surveys are done in summer", winter="plant surveys are done in winter")
factor_plant_2015_present = data.frame(attributeName = "season",
                                       code = names(Season),
                                       definition = unname(Season))

attributeList_plant_2015_present = set_attributes(plant_2015_present_attributes,
                                                  factor_plant_2015_present,
                                                  col_classes = c("Date", "factor", "numeric", 
                                                                  "numeric", "character", "numeric", 
                                                                  "numeric", "character"))

physical_plant_2015_present = set_physical(plant_2015_present)

dataTable_plant_2015_present = new("dataTable",
                                   entityName = "plant_2015_present.csv",
                                   entityDescription = "Plant censuses from 2015 to present",
                                   physical = physical_plant_2015_present,
                                   attributeList = attributeList_plant_2015_present,
                                   coverage = coverage_plant)

#====================================================================================
plant_census_dates_attributes = data.frame(
  attributeName=c("Year","Season","Census Done","Census Month","Census Days"),
  formatString=c("YYYY",NA,NA,NA,NA), 
  definition=c(NA,NA,NA,"month","days"), 
  unit=c("nominalYear","dimensionless","dimensionless",
         "dimensionless","nominalDay"),
  attributeDefinition=c("Year. Range: 1981-2015",
                        "Season: summer or winter",
                        "Whether Census is done: Yes or No",
                        "Month",
                        "Days"),
  numberType=c(NA,NA,NA,NA,NA),
  stringsAsFactors=FALSE)

Season = c(summer="plant surveys are done in summer", winter="plant surveys are done in winter")
Census_Done = c(Yes="Census is done", No="Census is not done")

factor_census_dates = rbind(data.frame(attributeName = "Season",
                                       code = names(Season),
                                       definition = unname(Season)),
                            data.frame(attributeName = "Census Done",
                                       code = names(Census_Done),
                                       definition = unname(Census_Done)))

attributeList_plant_census_dates = set_attributes(plant_census_dates_attributes, factor_census_dates, col_classes = c("Date", "factor","factor","character","character"))

physical_plant_census_dates = set_physical(plant_census_dates)

dataTable_plant_census_dates = new("dataTable",
                                   entityName = "plant_census_dates.csv",
                                   entityDescription = "Census Dates",
                                   physical = physical_plant_census_dates,
                                   attributeList = attributeList_plant_census_dates,
                                   coverage = coverage_plant)

#====================================================================================
plant_censuses_attributes = data.frame(
  attributeName=c("year","season","plot","quadrat","censused","area"),
  formatString=c("YYYY",NA,NA,NA,NA,NA), 
  definition=c(NA,NA,"plot number","quadrat number",NA,NA), 
  unit=c("nominalYear","dimensionless","number",
         "number","dimensionless","squareMeter"),
  attributeDefinition=c("Year. Range: 1981-2015",
                        "Season: summer or winter",
                        "Plot Number",
                        "Quadrat Number",
                        "whether censused: 1 or 0",
                        "area"),
  numberType=c(NA,NA,"integer","integer",NA,"real"),
  stringsAsFactors=FALSE)

Season = c(summer="plant surveys are done in summer", winter="plant surveys are done in winter")
Censused = c("1"="Census is done", "0"="Census is not done")

factor_census = rbind(data.frame(attributeName = "season",
                                 code = names(Season),
                                 definition = unname(Season)),
                      data.frame(attributeName = "censused",
                                 code = names(Censused),
                                 definition = unname(Censused)))

attributeList_plant_censuses = set_attributes(plant_censuses_attributes, factor_census, col_classes = c("Date", "factor","numeric","numeric","factor","numeric"))

physical_plant_censuses = set_physical(plant_censuses)

dataTable_plant_censuses = new("dataTable",
                               entityName = "plant_censuses.csv",
                               entityDescription = "Plant Census",
                               physical = physical_plant_censuses,
                               attributeList = attributeList_plant_censuses,
                               coverage = coverage_plant)

#=====================================================================================
plant_transects_2015_present_attributes = data.frame(
  attributeName=c("year","month","day","transect","plot","location","species","height","notes"),
  formatString=c("YYYY",NA,NA,NA,NA,NA,NA,NA,NA), 
  definition=c(NA,"month","day","transecton number","plot number","location number","species name",NA,"notes"), 
  unit=c("nominalYear","number","nominalDay","number","number",
         "number",NA,"meter",NA),
  attributeDefinition=c("Year",
                        "Month number",
                        "day",
                        "transection number",
                        "plot number",
                        "location number",
                        "species names",
                        "height",
                        "notes"),
  numberType=c(NA,"integer",NA,"integer","integer","integer",
               NA,"whole",NA),
  stringsAsFactors=FALSE)

attributeList_plant_transects_2015_present = 
  set_attributes(plant_transects_2015_present_attributes, col_classes = 
                   c("Date","numeric","character","numeric","numeric",
                     "numeric","character","numeric","character"))

physical_plant_transects_2015_present = set_physical(plant_transects_2015_present)

dataTable_plant_transects_2015_present = new("dataTable",
                                             entityName = "plant_transects_2015_present.csv",
                                             entityDescription = "plant_transects_2015_present",
                                             physical = physical_plant_transects_2015_present,
                                             attributeList = attributeList_plant_transects_2015_present,
                                             coverage = coverage_plant)

#Rodent
rodent = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Rodents/Portal_rodent.csv")
Encoding(rodent) = "latin1"
rodent = iconv(rodent, "latin1", "UTF-8", sub="")

rodent_datanotes = read.csv("https://raw.githubusercontent.com/weecology/PortalData/master/Rodents/Portal_rodent_datanotes.csv")
rodent_datanotes = as.data.frame(sapply(rodent_datanotes, function(x){
  x = as.character(x)
  Encoding(x) = "latin1"
  iconv(x, "latin1", "UTF-8", sub="")
}))

rodent_species = read.csv("https://raw.githubusercontent.com/weecology/PortalData/master/Rodents/Portal_rodent_species.csv")
rodent_species = as.data.frame(sapply(rodent_species, function(x){
  x = as.character(x)
  Encoding(x) = "latin1"
  iconv(x, "latin1", "UTF-8", sub="")
}))

rodent_trapping = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Rodents/Portal_rodent_trapping.csv")
Encoding(rodent_trapping) = "latin1"
rodent_trapping = iconv(rodent_trapping, "latin1", "UTF-8", sub="")

coverage_rodent = set_coverage(begin = '1977-07-16', end = '2016-07-03',
                               sci_names = as.character(rodent_species$ScientificName),
                               geographicDescription = geographicDescription,
                               west = -109.079844, east = -109.079844, 
                               north = 31.938969, south = 31.938969)

rodent_attributes = data.frame(
  attributeName=c("Record_ID","mo","dy","yr","period","plot","note1","stake","species","sex","reprod","age","testes","vagina","pregnant","nipples","lactation","hfl","wgt","tag","note2","ltag","note3","prevrt","prevlet","nestdir","neststk","note4","note5"),
  formatString=rep(NA, 29), 
  definition=c("Record_ID","mo","dy","yr","period","plot",NA,"stake","species","sex","reprod","age","testes","vagina","pregnant","nipples","lactation","hfl","wgt","tag","note2","ltag","note3","prevrt","prevlet","nestdir","neststk","note4","note5"), 
  unit=rep("dimensionless", 29),
  attributeDefinition=c("Record ID",
                        "month",
                        "day",
                        "year",
                        "period",
                        "plot number",
                        "note 1",
                        "stake number",
                        "species name",
                        "sex",
                        "reproductive condition",
                        "age",
                        "testes",
                        "vagina",
                        "pregnant",
                        "nipples",
                        "lactation",
                        "hfl",
                        "weight",
                        "tag",
                        "note2",
                        "ltag",
                        "note3",
                        "prevrt",
                        "prevlet",
                        "nestdir",
                        "neststk",
                        "note4",
                        "note5"),
  numberType=rep(NA, 29),
  stringsAsFactors=FALSE)

factors_rodent = data.frame(attributeName = "note1",
                            code = rodent_datanotes$Note1,
                            definition = rodent_datanotes$Meaning)

attributeList_rodent = set_attributes(rodent_attributes, factors_rodent, col_classes = c("character","character","character","character", "character","character","factor","character","character","character","character","character","character","character","character","character","character","character","character","character","character","character","character","character","character","character","character","character","character"))

physical_rodent = set_physical(rodent)

dataTable_rodent = new("dataTable",
                       entityName = "rodent.csv",
                       entityDescription = "rodent",
                       physical = physical_rodent,
                       attributeList = attributeList_rodent,
                       coverage = coverage_rodent)

#===============================================================================
rodent_trapping_attributes = data.frame(
  attributeName=c("Day","Month","Year","Period","Plot","Sampled"),
  formatString=c(NA,NA,"YYYY",NA,NA,NA), 
  definition=c("day","month",NA,"period number","plot number",NA), 
  unit=c("nominalDay","dimensionless","nominalYear","number",
         "number","dimensionless"),
  attributeDefinition=c("Day",
                        "Month",
                        "Year",
                        "Period",
                        "plot number",
                        "whether sampled"),
  numberType=c(NA,NA,NA,"integer","integer",NA),
  stringsAsFactors=FALSE)

factors_rodent_trapping = data.frame(attributeName = "Sampled",
                                     code = c("1","0"),
                                     definition = c("sampled","not sampled"))

attributeList_rodent_trapping = set_attributes(rodent_trapping_attributes, factors_rodent_trapping, col_classes = c("character","character","Date", "numeric","numeric","factor"))

physical_rodent_trapping = set_physical(rodent_trapping)

dataTable_rodent_trapping = new("dataTable",
                                entityName = "rodent_trapping.csv",
                                entityDescription = "rodent_trapping",
                                physical = physical_rodent_trapping,
                                attributeList = attributeList_rodent_trapping,
                                coverage = coverage_rodent)

#weather
weather = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Weather/Portal_weather.csv")
Encoding(weather) = "latin1"
weather = iconv(weather, "latin1", "UTF-8", sub="")

weather_19801989 = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/Weather/Portal_weather_19801989.csv")
Encoding(weather_19801989) = "latin1"
weather_19801989 = iconv(weather_19801989, "latin1", "UTF-8", sub="")

weather_attributes = data.frame(
  attributeName=c("Year","Month","Day","Hour","TempAir","Precipitation"),
  formatString=c("YYYY",NA,NA,NA,NA,NA), 
  definition=c(NA,"month","day","hr","air temperature","precipitation"), 
  unit=c("nominalYear","dimensionless","nominalDay","nominalHour",
         "celsius","millimeter"),
  attributeDefinition=c("Year",
                        "Month",
                        "Day",
                        "Time",
                        "air temperature",
                        "hourly precipitation"),
  numberType=c(NA,NA,NA,NA,"real","real"),
  stringsAsFactors=FALSE)

attributeList_weather = set_attributes(weather_attributes, col_classes = c("Date","character","character", "character","numeric","numeric"))

physical_weather = set_physical(weather)

dataTable_weather = new("dataTable",
                        entityName = "weather.csv",
                        entityDescription = "weather from 1989 to present",
                        physical = physical_weather,
                        attributeList = attributeList_weather)

#==================================================================================
weather_19801989_attributes = data.frame(
  attributeName=c("Year","Month","Day","MaxTemp","MinTemp","Precipitation"),
  formatString=c("YYYY",NA,NA,NA,NA,NA), 
  definition=c(NA,"month","day","max temperature",
               "min temperature","precipitation"), 
  unit=c(NA,NA,NA,"celsius","celsius","millimeter"),
  attributeDefinition=c("Year",
                        "Month",
                        "Day",
                        "Maximum temperature",
                        "Minimum temperature",
                        "Daily precipitation"),
  numberType=c(NA,NA,NA,"real","real","real"),
  stringsAsFactors=FALSE)

attributeList_weather_19801989 = set_attributes(weather_19801989_attributes, col_classes = c("Date","character","character", "numeric","numeric","numeric"))

physical_weather_19801989 = set_physical(weather)

dataTable_weather_19801989 = new("dataTable",
                                 entityName = "weather_19801989.csv",
                                 entityDescription = "weather from 1980 to 1989",
                                 physical = physical_weather_19801989,
                                 attributeList = attributeList_weather_19801989)
## Dataset
coverage = 
  set_coverage(begin = "1977", end = "2016",
               sci_names = as.character(c(as.character(ant_species$Scientific.Name), 
                                          plant_sci_names,
                                          as.character(rodent_species$ScientificName))),
               geographicDescription = geographicDescription,
               west = -109.079844, east = -109.079844, 
               north = 31.938969, south = 31.938969)

method = getURL("https://raw.githubusercontent.com/weecology/PortalData/master/SiteandMethods/README.md")
Encoding(method) = "latin1"
method = iconv(method, "latin1", "UTF-8", sub="")
method = gsub("[.*]","",method)
method = gsub("##*","",method)
write(method, file = "method.md")
methods = set_methods("method.md")

p1 = as.person("S. K. Morgan Ernest [aut]<skmorgane@ufl.edu>")
p1 = as(p1, "creator")

others = c(as.person("Glenda M. Yenni [aut]"), as.person("Ginger Allington [aut]"),
           as.person("Erica M. Christensen [aut]"), as.person("Keith Geluso [aut]"),
           as.person("Jacob R. Goheen [aut]"), as.person("Michelle R. Schutzenhofer [aut]"),
           as.person("Sarah R. Supp [aut]"), as.person("Katherine M. Thibault [aut]"),
           as.person("James H. Brown [aut]"), as.person("Thomas J. Valone [aut]"))

associatedParty = as(others, "associatedParty")

address = new("address",
              deliveryPoint = "Department of Wildlife Ecology and Conservation, IFAS
                                110 Newins-Ziegler Hall, PO Box 110430",
              city = "Gainesville",
              administrativeArea = "FL",
              postalCode = "32611",
              country = "USA")

publisher = new("publisher",
                organizationName = "Ecological Society of America",
                address = address)
contact = 
  new("contact",
      individualName = p1@individualName,
      electronicMail = p1@electronicMailAddress,
      address = address,
      organizationName = "Ecological Society of America")

keywordSet = new("keywordSet",
                 keyword = c("annual plants", "ants", 
                             "Chihuahuan desert", "long-term data", 
                             "precipitation", "rodents", "temperature"))

pubDate = "2016"

title = "Long-term monitoring and experimental manipulation of a Chihuahuan Desert ecosystem near Portal, Arizona"

abstract = "Desert ecosystems have long served as model systems in the study of ecological concepts (e.g., competition, resource pulses, top-down/bottom-up dynamics). However, the inherent variability of resource availability in deserts, and hence consumer dynamics, can also make them challenging ecosystems to understand. Study of a Chihuahuan desert ecosystem near Portal, AZ began in 1977. At this site, 24 experimental plots were established in 1977 and divided among controls and experimental manipulations. Experimental manipulations over the years include removal of all or some rodent species, all or some ants, seed additions, and various alterations of the annual plant community. These data have been used in a variety of publications documenting the effects of the experimental manipulations as well as the response of populations and communities to long-term changes in climate and habitat. Sampling is ongoing and additional data will be published as it is collected."  

intellectualRights = "Standard scientific norms for attribution and credit should be followed when using these 
                      data, including to the original sources. This work is licensed under a Creative Commons 
                      Attribution 4.0 International License (CC-BY; http://creativecommons.org/licenses/by/4.0/)."

## EML file
dataset = new("dataset",
              title = title,
              creator = p1,
              pubDate = pubDate,
              intellectualRights = intellectualRights,
              abstract = abstract,
              associatedParty = associatedParty,
              keywordSet = keywordSet,
              coverage = coverage,
              contact = contact,
              methods = methods,
              dataTable = c(dataTable_bait, dataTable_colony, dataTable_plant_1981_2015,
                            dataTable_plant_2015_present, dataTable_plant_census_dates,
                            dataTable_plant_censuses, 
                            dataTable_plant_transects_2015_present,
                            dataTable_rodent, dataTable_rodent_trapping,
                            dataTable_weather, dataTable_weather_19801989))

eml = new("eml",
          packageId = "cfced01b-ca07-4f71-9543-a01365c6099d",  # from uuid::UUIDgenerate(),
          system = "uuid", # type of identifier
          dataset = dataset)

testthat::expect_true(eml_validate(eml))

write_eml(eml, "PortalData.xml")
