#Functions for retrieving and processing NDVI data for Portal.
#Currently only GIMMS is supported, with years 1981-2013 available.
# This code is modified from get_ndvi_data.R script in the Weecology repo: BBS-forecasting
#(https://github.com/weecology/bbs-forecasting/blob/master/R/get_ndvi_data.R)
# Modified for Portal by Morgan Ernest and Shawn Taylor

#GIMMS: Call get_gimms_ndvi() to retrieve a dataframe of (year, month, ndvi).
#-It will take a while to download the 14gb of data and extract values the 1st time around. 
#-To redo it just delete the database file.
#-na values are due to missing periods from filtering out unwanted quality flags.
library(dplyr)
library(gimms)
library(sp)
library(rgdal)

#################################################
#This assumes we want all gimms files that are available. It queries for files
#that are available for download and compares against files already in the gimms
#data directory.
#Returns a list of files to download, which may be length 0.
##################################################
get_gimms_download_list=function(gimms_folder = './GIMMS'){
  available_files_download_path=gimms::updateInventory(version=0)
  available_files_name=basename(available_files_download_path)

  files_present=list.files(gimms_folder)
  #hdr files are created from some of the gimms processing that we don't want to
  #use here.
  files_present=files_present[!grepl('hdr', files_present)]

  to_download=available_files_download_path[! available_files_name %in% files_present]

  return(to_download)
}

################################################
#Extract values from a single gimms file given a set of coordinates.
#Excludes values which don't meet NDVI quality flags.
#From the GIMMS readme:
#FLAG = 7 (missing data)
#FLAG = 6 (NDVI retrieved from average seasonal profile, possibly snow)
#FLAG = 5 (NDVI retrieved from average seasonal profile)
#FLAG = 4 (NDVI retrieved from spline interpolation, possibly snow)
#FLAG = 3 (NDVI retrieved from spline interpolation)
#FLAG = 2 (Good value)
#FLAG = 1 (Good value)
################################################
extract_gimms_data=function(gimms_file_path, site){
  gimmsRaster=rasterizeGimms(gimms_file_path, keep=c(1,2,3))
  ndvi=raster::extract(gimmsRaster, site, buffer=4000)
  ndvi=as.numeric(lapply(ndvi, mean, na.rm=TRUE))

  year=as.numeric(substr(basename(gimms_file_path), 4,5))
  month=substr(basename(gimms_file_path), 6,8)
  day=substr(basename(gimms_file_path), 11,11)

  #Convert the a b to the 1st and 15th
  day=ifelse(day=='a',1,15)

  #Convert 2 digit year to 4 digit year
  year=ifelse(year>50, year+1900, year+2000)

  return(data.frame(year=year, month=month, day=day, ndvi=ndvi, stringsAsFactors = FALSE))
}

################################################
#Extract the NDVI time series for all bbs routes
#from all years of gimms data
################################################
process_gimms_ndvi=function(gimms_folder = './GIMMS'){
  long = -109.08029
  lat = 31.937769
  site <- data.frame(long,lat)
  coordinates(site) <- c("long", "lat")

  gimms_files=list.files(gimms_folder, full.names = TRUE)
  #hdr files are created from some of the gimms processing that we don't want to
  #use here.
  gimms_files=gimms_files[!grepl('hdr', gimms_files)]

  gimms_ndvi=data.frame()
  for(file_path in gimms_files){
    gimms_ndvi=extract_gimms_data(file_path, site) %>%
      bind_rows(gimms_ndvi)
  }

  #Get a single value per site/month/year. NA values
  #are kept. These are from where the quality flag was not met.
  gimms_ndvi = gimms_ndvi %>%
    group_by(year, month) %>%
    summarize(ndvi=mean(ndvi, na.rm=TRUE)) %>%
    ungroup()

  return(gimms_ndvi)
}

#################################################
#Get the GIMMS AVHRR ndvi bi-monthly time series for every bbs site.
#Pulling from the sqlite DB or extracting it from raw gimms data if needed.
#################################################
get_gimms_ndvi = function(gimms_folder = './GIMMS'){
  dir.create(gimms_folder, showWarnings = FALSE, recursive = TRUE)

  files_to_download=get_gimms_download_list(gimms_folder = gimms_folder)
  if(length(files_to_download)>0){
    print('Downloading GIMMS data')
    downloadGimms(x=files_to_download, dsn=gimms_folder)
  }

  gimms_ndvi_data=process_gimms_ndvi(gimms_folder = gimms_folder)

  return(gimms_ndvi_data)

}

###############################
#MASTER CODE FOR CALLING THE FUNCTIONS
###############################
portal_ndvi = get_gimms_ndvi(gimms_folder = './')

# Change monthly abbreviations to month number
portal_ndvi$month = match(ndvi$month, tolower(month.abb))

write.csv(portal_ndvi, 'NDVI/monthly_NDVI.csv', row.names=FALSE)
