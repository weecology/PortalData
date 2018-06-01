##Used in the original cleaning and reshaping of transect data from 1989 - 2009
##Modified from https://github.com/sdtaylor/portalShrubs/blob/master/processRawTransectData.R
##Final data saved in the file: PortalData/Plants/Portal_plant_transects_1989_2009.csv

library(tidyr)
library(dplyr)
library(stringr)
library(readxl)
library(testthat)
csvFolder='~/portalShrubs/shrubData/excelExports/'

species=read.csv(paste('../Plants/Portal_plant_species.csv',sep='')) %>%
  mutate(Species.Name = paste(genus,species,sep=" ")) %>%
  distinct(Species.Name,.keep_all = TRUE)

##Table of all transect names over time
transect_names=data.frame(previous=c("A","B","C","D","NW","NE","SE","SW"),now=c("NW","NE","SE","SW","NW","NE","SE","SW"))

#Each year of transect data is slightly different, so requires it's own processing
#################################
#################################
### 1989
speciesList89=read.csv(paste(csvFolder, '1989_species_list_ShawnsEdits.csv',sep='')) %>%
  mutate_if(is.factor,as.character) %>%
  mutate(Species.Name=replace(Species.Name,Code.Number==24,"Tragus berteronianus"))

#Read in and reshape data
year89=read.csv(paste(csvFolder,'89in.csv',sep='')) %>%
  gather(Plot, SpeciesID, -Transect, -Point) %>%
  mutate(Plot=substring(Plot, 5), year=1989,
         SpeciesID = replace(SpeciesID,SpeciesID==19,'6,40'),
         SpeciesID = replace(SpeciesID,SpeciesID==16,10)) %>%
  mutate_if(is.factor,as.character) %>%
  
  #repeat columns for multiple entries
  mutate(SpeciesID = strsplit(as.character(SpeciesID), ",")) %>%
  unnest(SpeciesID) %>%
  
  #Assign species names
  merge(speciesList89, by.x='SpeciesID',by.y='Code.Number') %>%
  select(Transect, Point, Plot, year, Species.Name)

which(is.na(year89$Species.Name))

########
### 1992
speciesList92=read.csv(paste(csvFolder, '1992_species_list_ShawnsEdits.csv',sep='')) %>%
  mutate_if(is.factor,as.character) %>%
  mutate(Species.Name=replace(Species.Name,Code.Number==25,"Bare ground"),
         Species.Name=replace(Species.Name,Code.Number==43,"Opuntia sp."))

year92=read.csv(paste(csvFolder,'92in.csv',sep='')) %>%
  gather(Plot, SpeciesID, -Transect, -Point) %>%
  mutate(Plot=substring(Plot, 5), year=1992) %>%
  merge(speciesList92, by.x='SpeciesID',by.y='Code.Number') %>%
  select(Transect, Point, Plot, year, Species.Name) %>%
  mutate_if(is.factor,as.character)

which(is.na(year92$Species.Name))

########
### 1995
speciesList95=read.csv(paste(csvFolder, '1995_species_list_ShawnsEdits.csv',sep='')) %>%
  mutate_if(is.factor,as.character) %>%
  rbind(data.frame(Code.Number=c("*","?"),Species.Name=c("Sphaeralcea sp.","Panicum sp."),
                   Group=c("Perennial Forb","Annual Grass"))) %>%
  mutate(Species.Name=replace(Species.Name,Code.Number==0,"Bare ground"),
         Species.Name=replace(Species.Name,Code.Number=="shrub?","Unknown shrub"),
         Species.Name=replace(Species.Name,Code.Number=="little plant","Unknown annual forb"),
         Species.Name=replace(Species.Name,Code.Number=="f","Unknown annual forb"),
         Species.Name=replace(Species.Name,Code.Number=="f","Unknown annual forb"))

year95=read.csv(paste(csvFolder,'95in.csv',sep='')) %>%
  mutate_if(is.factor,as.character) %>% 
  gather(Plot, SpeciesID, -Transect, -Position) %>%
  mutate(Plot= substring(Plot, 5), year = 1995) %>%
  rename(Point = Position) %>%
  
  #fix typos in data entry
  mutate(SpeciesID=replace(SpeciesID,SpeciesID=="*" && Plot==7,"f"),
         SpeciesID=replace(SpeciesID,SpeciesID=="*" && Plot==19,"shrub?"),
         SpeciesID=replace(SpeciesID,SpeciesID=="cc","c"),
         SpeciesID=replace(SpeciesID,SpeciesID=="dd" && Plot==6,"44"),
         SpeciesID=replace(SpeciesID,SpeciesID=="dd" && Plot==9,"55"),
         SpeciesID=replace(SpeciesID,SpeciesID=="dd","d"),
         SpeciesID=replace(SpeciesID,SpeciesID=="65d51","65,51"),
         SpeciesID=replace(SpeciesID,SpeciesID=="511","51"),
         SpeciesID=replace(SpeciesID,SpeciesID=="cd","c"),
         SpeciesID=replace(SpeciesID,SpeciesID=="89.41","99"),
         SpeciesID=replace(SpeciesID,SpeciesID=="102","c"),
         SpeciesID=replace(SpeciesID,SpeciesID %in% c("89t","89+","89,t"),"89"),
         SpeciesID=replace(SpeciesID,SpeciesID=="17,a","17a"),
         SpeciesID=replace(SpeciesID,SpeciesID %in% c("bk?","dr",'153'),"r")) %>%  
  
  #speciesID has multiple hits per point in the form of "45,34,2"
  mutate(SpeciesID = strsplit(as.character(SpeciesID), ",")) %>%
  unnest(SpeciesID) %>%
  mutate(SpeciesID=replace(SpeciesID,SpeciesID %in% c("","t","+"),"c")) %>%

  #Assign species names
  left_join(speciesList95, by=c('SpeciesID' = 'Code.Number'))  %>%
  select(Transect, Point, Plot, year, Species.Name)

get = c(which(is.na(year95$Species.Name)),which(year95$Species.Name==""))
year95[get,]
########
### 1998
speciesList98=read.csv(paste(csvFolder, '1998_species_list_ShawnsEdits.csv',sep='')) %>%
  mutate_if(is.factor,as.character) %>%
  mutate(Species.Name=replace(Species.Name,Code.Number=="","Bare Soil")) %>%
  rbind(data.frame(Code.Number=c("s","uj","c","9a","*"),Species.Name=c("Unknown Shrub","Unknown Forb","Cuscuta sp.",
                                                                   "Aristida sp.","Carlowrightia linearifolia"),
                   Group=c("Shrub","Annual Forb","Annual Forb","Annual Grass","Shrub")))

year98=read.csv(paste(csvFolder,'98in.csv',sep=''), na.strings=c('')) %>%
  mutate_if(is.factor,as.character) %>% 
  gather(Plot, SpeciesID, -Transect, -Position) %>%
  mutate(Plot =substring(Plot, 5), year = 1998) %>%
  rename(Point = Position) %>%
  filter(!is.na(SpeciesID)) %>%
  #fix typos in data entry
  mutate(SpeciesID=replace(SpeciesID,SpeciesID=="t","r"),
         SpeciesID=replace(SpeciesID,SpeciesID=="fg","95"),
         SpeciesID=replace(SpeciesID,SpeciesID=="92a8","92,8")) %>%
  mutate(SpeciesID = strsplit(as.character(SpeciesID), ",")) %>%
  unnest(SpeciesID) %>%
  filter(SpeciesID!="") %>%
  left_join(speciesList98, by=c('SpeciesID' = 'Code.Number'))  %>%
  select(Transect, Point, Plot, year, Species.Name)

get = which(is.na(year98$Species.Name))
year98[get,]

########
### 2001
speciesList01=read.csv(paste(csvFolder, '2001_species_list_ShawnsEdits.csv',sep='')) %>%
  rbind(data.frame(Code.Number=c("m",0),Species.Name=c("Prosopis sp.","Bare Soil"),Group=c("Shrub",NA)))

year01=read.csv(paste(csvFolder,'01in.csv',sep=''), na.strings=c('')) %>%
  mutate_if(is.factor,as.character) %>% 
  gather(Plot, SpeciesID, -Transect, -Position) %>%
  mutate(Plot =substring(Plot, 5), year = 2001) %>%
  filter(!is.na(SpeciesID)) %>%
  rename(Point = Position) %>%
  #fix typos in data entry
  mutate(SpeciesID=replace(SpeciesID,SpeciesID=="413","41")) %>%
  mutate(SpeciesID = strsplit(as.character(SpeciesID), ",")) %>%
  unnest(SpeciesID) %>%
  
  left_join(speciesList01, by=c('SpeciesID' = 'Code.Number'))  %>%
  select(Transect, Point, Plot, year, Species.Name) %>%
  mutate_if(is.factor,as.character)

get=which(is.na(year01$Species.Name))
year01[get,]

########
### 2004 and 2009 are very different in format, and do not have transect/point info

read_excel_allsheets <- function(filename,columns) {
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X, 
                                  range = cell_cols(columns), col_names = FALSE, col_types = "text"))
  names(x) <- sheets
  x
}

########
### 2004
speciesList04=speciesList98

year04 = read_excel_allsheets(paste(csvFolder,'transects_2004_in.xls',sep=''),columns="A") %>%
        plyr::ldply(data.frame) %>%
        rename(Plot = .id, SpeciesID = X__1) %>%
        mutate(Plot=substring(Plot, 5), year=2004, Transect = NA, Point = NA, SpeciesID = tolower(SpeciesID),
               #typo, assuming code 411 is 41
               SpeciesID = replace(SpeciesID, SpeciesID==411, 41)) %>%
  
  left_join(speciesList04, by=c('SpeciesID' = 'Code.Number'))  %>%
  select(Transect, Point, Plot, year, Species.Name) 

which(is.na(year04$Species.Name))

########
### 2009
speciesList09 = speciesList98

## In this year, multiple hits are listed in separate columns
year09_1 = read_excel_allsheets(paste(csvFolder,'transects_2009_in.xls',sep=''),columns="A:C") %>%
  plyr::ldply(data.frame) %>%
  rename(Plot = .id, SpeciesID = X__1) %>%
  mutate(Plot=substring(Plot, 5), year=2009, Transect = NA, Point = NA) 

year09_2 = select(year09_1,c(Plot, SpeciesID = X__2, year, Transect, Point)) %>%
            filter(!is.na(SpeciesID))
year09_3 = select(year09_1,c(Plot, SpeciesID = X__3, year, Transect, Point)) %>%
  filter(!is.na(SpeciesID))

year09 = year09_1[-1,] %>%
  select(Plot, SpeciesID, year, Transect, Point) %>%
  rbind(year09_2[-1,],year09_3[-1,]) %>%
  mutate(SpeciesID = tolower(SpeciesID)) %>%
  filter(!is.na(SpeciesID)) %>%
  left_join(speciesList09, by=c('SpeciesID' = 'Code.Number'))  %>%
  select(Transect, Point, Plot, year, Species.Name) 

which(is.na(year09$Species.Name))

#####################################################
##Combine all years and do final cleanup
all_transects = rbind(year89,year92,year95,year98,year01,year04,year09) %>%
  rename(plot=Plot, transect=Transect, point=Point) %>%
  left_join(transect_names,by = c('transect' = 'previous')) %>%
  select(-transect) %>% rename(transect = now) %>%
  mutate_if(is.factor,as.character) %>% 
  
  #Fix species names to match species list
  mutate(Species.Name = replace(Species.Name,Species.Name=="Trichachne californica",'Digitaria californica'),
         Species.Name = replace(Species.Name,Species.Name %in% 
                                  c("Aristida longiseta","Aristidia glauca"),'Aristida purpurea'),
         Species.Name = replace(Species.Name,Species.Name=="Sprorobolus contractus",'Sporobolus contractus'),
         Species.Name = replace(Species.Name,Species.Name=="Bouteloua eriopoda",'Chondrosum eriopodum'),
         Species.Name = replace(Species.Name,Species.Name %in% 
                                  c("Triden pulchellus","Tridens pulchellum"),'Erioneuron pulchellum'),
         Species.Name = replace(Species.Name,Species.Name %in% 
                                  c("Boutelousa barbata","Bouteloua barbata"),'Chondrosum barbatum'),
         Species.Name = replace(Species.Name,Species.Name=="Panicum arizonicum",'Brachiaria arizonica'),
         Species.Name = replace(Species.Name,Species.Name %in% c("open sand","open rock","Bare ground",
                                  "Bare rock","Dead Plant","Clear","Rock","Plant Litter","Bare Soil",""),NA),
         Species.Name = replace(Species.Name,Species.Name %in% 
                                  c("herbaceous plant","unknown","Unknown Forb"),"Unknown forb"),
         Species.Name = replace(Species.Name,Species.Name=="Prosopis","Prosopis sp."),
         Species.Name = replace(Species.Name,Species.Name=="Gutierrezia sarothrae","Gutierrezia microcephala"),
         Species.Name = replace(Species.Name,Species.Name=="Zinnia","Zinnia sp."),
         Species.Name = replace(Species.Name,Species.Name=="Happlopappus","Haplopappus sp."),
         Species.Name = replace(Species.Name,Species.Name %in%
                                  c("mystery shrub","Unknown Shrub"),"Unknown shrub"),
         Species.Name = replace(Species.Name,Species.Name=="Haplopappus gracilis","Machaeranthera gracilis"),
         Species.Name = replace(Species.Name,Species.Name=="Erograstis lehmanniana","Eragrostis lehmanniana"),
         Species.Name = replace(Species.Name,Species.Name %in% 
                                  c("Talinum aurantianum","Talinum aurantiacum"),"Phemeranthus aurantiacus"),
         Species.Name = replace(Species.Name,Species.Name %in% 
                                  c("Machaeranthera tanaecefolia","Machaeranthera tanreafolia"),"Machaeranthera tagetina"),
         Species.Name = replace(Species.Name,Species.Name %in% 
                                  c("Croton corymbulosa","Croton corymbulosa "),"Croton potsii"),
         Species.Name = replace(Species.Name,Species.Name=="Aristida adscensnis","Aristida adscensionis"),
         Species.Name = replace(Species.Name,Species.Name=="Talinum angustissimum","Phemeranthus angustissimum"),
         Species.Name = replace(Species.Name,Species.Name %in%
                                  c("Dalea brachystachys","Delea brachystachys"),"Dalea brachystachya"),
         Species.Name = replace(Species.Name,Species.Name=="Portulaca parvula","Portulaca halimoides"),
         Species.Name = replace(Species.Name,Species.Name=="Zinnia pumila","Zinnia acerosa"),
         Species.Name = replace(Species.Name,Species.Name %in%
                                  c("Aristida homulosa","Aristida hamulosa"),"Aristida ternipes"),
         Species.Name = replace(Species.Name,Species.Name=="Sida procumbens","Sida abutifolia"),
         Species.Name = replace(Species.Name,Species.Name %in% 
                                  c("Cassia bauhinoides","Cassia bauhinioides"),"Senna bauhinoides"),
         Species.Name = replace(Species.Name,Species.Name=="Haplopappus tenuisectus","Isocoma tenuisecta"),
         Species.Name = replace(Species.Name,Species.Name=="Helianthus annua","Helianthus annuus"),
         Species.Name = replace(Species.Name,Species.Name=="Boutoluoa aristidoides","Bouteloua aristidoides"),
         Species.Name = replace(Species.Name,Species.Name=="Chenopodium frementii","Chenopodium fremontii"),
         Species.Name = replace(Species.Name,Species.Name=="Setaria macrostacha","Setaria macrostachya"),
         Species.Name = replace(Species.Name,Species.Name=="Boerhaavia intermedia","Boerhavia intermedia"),
         Species.Name = replace(Species.Name,Species.Name=="Brayulinea densa","Guilleminea densa"),
         Species.Name = replace(Species.Name,Species.Name=="Eurotia lanata","Krascheninnikovia lanata"),
         Species.Name = replace(Species.Name,Species.Name=="Boerhaavia torreyana","Boerhavia spicata"),
         Species.Name = replace(Species.Name,Species.Name=="Boerhaavia coulteri","Boerhavia coulteri"),
         Species.Name = replace(Species.Name,Species.Name=="Dichlostema pulchellum","Dichlostemma capitatum"),
         Species.Name = replace(Species.Name,Species.Name=="Hoffmanseggia densiflora","Hoffmanseggia glauca"),
         Species.Name = replace(Species.Name,Species.Name=="Sida physocalyx","Rhynchosida physocalyx"),
         Species.Name = replace(Species.Name,Species.Name=="Boerhaavia coccinea","Boerhavia coccinea"),
         Species.Name = replace(Species.Name,Species.Name=="Beavertail","Opuntia basilaris"),
         Species.Name = replace(Species.Name,Species.Name=="Cholla","Cylindropuntia sp."),
         Species.Name = replace(Species.Name,Species.Name=="Apondanthera undulata","Apodanthera undulata"),
         Species.Name = replace(Species.Name,Species.Name=="Cassia leptadenia","Chamaecrista nictitans"),
         Species.Name = replace(Species.Name,Species.Name=="Crotalaria pumila ","Crotalaria pumila"),
         Species.Name = replace(Species.Name,Species.Name=="Ambrosia artemisifolia","Ambrosia artemisiifolia"),
         Species.Name = replace(Species.Name,Species.Name=="Boerhaavia sp.","Boerhavia sp.")) %>%
  filter(!is.na(Species.Name)) %>%
  left_join(species) %>%
  select(year,plot,transect,species=speciescode,point) %>%
  mutate(year = as.integer(year), plot = as.integer(plot),
         transect = as.character(transect), species=as.character(species), point = as.integer(point)) %>%
  arrange(year,plot,transect,point,species)

##########
#Tests
test_that("valid year", {
  
  expect_true(all(all_transects$year %in% c(1989,1992,1995,1998,2001,2004,2009)))
})

test_that("valid plot", {
  
  expect_true(all(all_transects$plot %in% 1:24))
})

test_that("valid transect", {
  
  expect_true(all(all_transects$transect %in% c("NW","SW","NE","SE",NA)))
})

test_that("valid species", {
  
  expect_true(all(all_transects$species %in% species$speciescode))
})

test_that("valid point", {
  
  expect_true(all(all_transects$point %in% c(1:250,NA)))
})

write.csv(all_transects,"../Plants/Portal_plant_transects_1989_2009.csv",row.names = FALSE,na = "")
