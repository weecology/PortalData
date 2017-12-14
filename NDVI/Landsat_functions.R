# written by Erica Christensen 12/13/17
# adapted from some older code from 2015 that I used to process huge raster files downloaded from earthexplore.usgs.gov
# main code to process landsat data contained in Landsat_data_processing.Rmd


library(raster)
library(rgdal)
library(dplyr)



# ==================================================================================
# generate list of scene files to be processed

# flist = read.csv("C:/Users/EC/Documents/Portal_EC/NDVI/scenelists/L7_all.txt",header=F,sep='\t')
# filelist = vector()
# for (n in flist) {
#   name = as.character(n)
#   filelist = append(filelist,name)
# }
# 
# #==========================================================================
# # Extract desired files from downloaded .tar files, and metadata files
# 
# tarfolder = 'F:/Landsat7'
# tarfiles = list.files(tarfolder)
# 
# targetpath = 'C:/Users/EC/Documents/Portal_EC/NDVI/L7'
# outfpath = 'C:/Users/EC/Documents/Portal_EC/NDVI/L7 crop/'
# 
# for (f in filelist) {
#   fid = substr(f,1,16)                               # file identifier (first 16 characters of file name)
#   tarf = grep(fid,tarfiles,value=T)                  # find corresponding .tar file 
#   band_files = c(paste(f,'_cfmask.tif',sep=''),      # list of files to extract: mask, bands, and metadata
#                  paste(f,'_MTL.txt',sep=''),
#                  paste(f,'_sr_ndvi.tif',sep=''))
#   untar(paste(tarfolder,'/',tarf,sep=''),
#         exdir = targetpath,
#         files = band_files)
# }

# ============================================================================================
# functions

#' @title crop_raster
#' @description crops raster file to specified area; default values are 1.125km in all directions from center of Portal Project
#'
#' @param raster_file file name of raster data
#' @param xmin
#' @param xmax
#' @param ymin
#' @param ymax
#'
crop_raster = function(raster_file,xmin=680317,xmax=682613,ymin=3534011,ymax=3536291) {
  r = raster(raster_file)
  r1 = crop(r,extent(xmin,xmax,ymin,ymax))
  
  return(r1)
}


#' @title mask_raster
#' @description uses mask file to set pixels covered by cloud to NA
#' 
#' @param ndvi_file file name of ndvi data
#' @param mask_file file name of mask
#' 
#' @return raster matching size of ndvi_file but with clouded pixels set to NA
#' 
mask_raster = function(ndvi_file,mask_file) {
  scene1 = raster(ndvi_file)
  cloud = raster(mask_file)
  cloud[cloud>0]=NA
  
  s1 = mask(scene1,cloud)
  return(s1)
}

# --------------------------WIP-------------------------------------------------
#' @title summarize_ndvi  
#' @description summarize data for whole year in csv doc
#' 
#' @param 
#' 
#' @return data frame of one row: contains summary statistics for single raster image
#' 
summarize_ndvi_snapshot = function(name) {
  
  sat = as.character(substr(name,3,3))
  path = as.integer(substr(name,4,6))
  rows = as.integer(substr(name,7,9))
  yr = as.integer(substr(name,10,13))
  jday = as.integer(substr(name,14,16))
  gs = substr(name,17,19)
  ver = substr(name,20,21)
  
  r = raster(paste(outmaskedpath,name,'_ndvi_masked.tif',sep=''))
  # cloud cover
  pct = sum(is.na(values(r)))/length(values(r))*100
  
  stdev = sd(values(r),na.rm=T)
  mn = mean(values(r),na.rm=T)
  md = median(values(r),na.rm=T)
  mi = min(values(r),na.rm=T)
  ma = max(values(r),na.rm=T)
  ra = ma-mi
  sm = sum(values(r),na.rm=T)
  va = var(values(r),na.rm=T)
  pix = length(values(r))
  
  d = data.frame(satellite=sat,path=path,rows=rows,year=yr,julianday=jday,groundstation=gs,
                 version=ver,stdev=stdev,mean=mn,median=md,min=mi,max=ma,range=ra,sum=sm,
                 variance=va,numpixels=pix,pctcloud=pct)
  return(d)
}


#' @title remove_cloud
#' @description takes data frame of summarized ndvi images and removes rows based on a threshold cloud cover
#'
#' @param ndvi_frame data frame containing summarized ndvi data (output of summarize_ndvi_snapshot)
#' @param threshold number: images with cloud cover greater than this will be discarded

remove_cloud_images = function(ndvi_frame, threshold) {
  ndvi_filtered = filter(ndvi_frame,pctcloud<threshold)
  return(ndvi_filtered)
}

#' @title find_matching_image
#' @description given two data frames, finds rows from second data frame within 3 days of each row from first data frame. discards row with no match
#' 
#' @param sat1 data frame of first satellite
#' @param sat2 data frame of second satellite
#' 
find_matching_image = function(sat1,sat2) {
  end_frame = data.frame()
  for (n in row.names(sat1)) {
    image = sat1[n,]
    image2 = sat2 %>% filter(date<image$date+4) %>% filter(date>image$date-4)
    
    if (nrow(image2)>0) {
      comp_row = data.frame(sat2_date=image2$date, sat2_ndvi=image2$median, sat1_date=image$date, sat1_ndvi=image$median)
      end_frame = rbind(end_frame,comp_row)
    }
  }
  return(end_frame)
}


#' @title NDVI regression
#' @description takes two lists of NDVI data and returns intercept and pvalue
#' 
#' @param x_NDVI
#' @param y_NDVI
#' 
NDVI_regression = function(x_NDVI, y_NDVI){
  NDVI.lm = lm(y_NDVI ~ x_NDVI)
  stat.coef = summary(NDVI.lm)$coefficients
  intercept = stat.coef[1,1]
  pvalue = stat.coef[1,4]
  return(c(intercept, pvalue))
}

#' @title apply correction
#' @description apply appropriate correction factor to NDVI data, if pvalue is small
#' 
#' @param df_NDVI vector of ndvi data
#' @param correction output of NDVI_regression: (intercept, pvalue)
#' 
#' @return corrected vector of ndvi data
#' 
Apply_correction = function(df_NDVI, correction){
  if (correction[2] < 0.1){
    intercept = correction[1]
  } else {
    intercept = 0
  }
  return(df_NDVI - intercept)
}

# =====================================================================
# main code


# data = data.frame(Satellite=as.character(),Path=as.integer(),Rows=as.integer(),Year=as.integer(),
#                   JulianDay=as.integer(),GroundStation=as.character(),Version=as.character(),
#                   StDev=as.numeric(),Mean=as.numeric(),Median=as.numeric(),Min=as.numeric(),
#                   Max=as.numeric(),Range=as.numeric(),Sum=as.numeric(),Variance=as.numeric(),
#                   NumPixels=as.numeric(),PctCloud=as.numeric())
# 
# for (name in filelist) {
#   d = summarize_ndvi_snapshot(name)
#   data = rbind(data,d)
# }
# 
# write.csv(data,file='C:/Users/EC/Documents/Portal_EC/NDVI/LandsatNDVI_L7.csv',row.names=F,col.names=F)
