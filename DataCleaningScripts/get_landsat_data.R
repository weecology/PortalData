# written by Erica Christensen 1/8/15; modified 1/25/18
# This script processes Landsat8 data from compressed file to NDVI calculation

library(raster)
library(rgdal)
library(dplyr)


# Steps each file goes through:
#    1. extract raster files from compressed file
#    2. crop ndvi and QA rasters to area around Portal
#    3. delete large raster files, save small raster files to separate folder
#    4. use QA raster to mask bad pixels
#    5. apply scale factor (.0001)
#    6. summarize masked and cropped ndvi image to get mean ndvi value per image
#  then compile summarized data for all files into a single csv

############################################################################
# Functions
############################################################################

#' @title create_portal_box
#' 
#' @description creates a square SpatialPolygons object centered at a given lon/lat point and a given radius from that point.
#'              CRS must be specified
#'              center of Portal: 31.937769, -109.08029
#'              corners of Portal: NW = 31.939568, -109.083177
#'                    NE = 31.939569, -109.077460
#'                    SW = 31.935860, -109.082948
#'                    SE = 31.935948, -109.077317
#' 
#' @param centroid vector of coordinates in lon/lat of center of box [lon,lat]
#' @param radius desired radius, in m
#' @param portal_crs CRS of desired SpatialPolygons object, needs to match rasters
#' 
#' @return portal_box is a SpatialPolygons object that can be used for cropping rasters
#' 
#' @example create_portal_box(centroid = c(-109.08029, 31.937769), radius = 1125, 
#'                            portal_crs = CRS("+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0 "))
#' 
create_portal_box = function(centroid=c(-109.08029, 31.937769), 
                             radius=1125, 
                             portal_crs=CRS("+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0 ")) {
  # create SpatialPointsDataFrame of centroid of site
  center <- data.frame(ID = 1, X = centroid[1], Y = centroid[2])
  coordinates(center) <- c("X", "Y")
  proj4string(center) <- CRS("+proj=longlat +datum=WGS84")
  
  # convert centroid to UTM and make box
  cent_utm <- spTransform(center, portal_crs)
  xmin = cent_utm@coords[1,1]-radius
  xmax = cent_utm@coords[1,1]+radius
  ymin = cent_utm@coords[1,2]-radius
  ymax = cent_utm@coords[1,2]+radius
  
  square=cbind(xmin,ymax,  # NW corner
               xmax,ymax,  # NE corner
               xmax,ymin,  # SE corner
               xmin,ymin,  # SW corner
               xmin,ymax)  # NW corner again
  a <- vector('list', length(2))
  a[[1]]<-Polygons(list(Polygon(matrix(square[1, ], ncol=2, byrow=TRUE))), 1) 
  portal_box<-SpatialPolygons(a,proj4string=portal_crs)
  
  return(portal_box)
  
}

#' @title plot Portal bounds
#' @description plots box to be used to crop raster, and corners of the cattle fence
#' @param portal_box output of create_portal_box()
#'
plot_portal_bounds = function(portal_box) {

  # Lon/Lat points estimated from google earth image
  corners = data.frame(ID = 1:4, X = c(-109.083177,-109.077460,-109.082948,-109.077317),
                       Y = c(31.939568,31.939569,31.935860,31.935948))
  # this crs should be the default for all downloaded rasters
  portal_crs = CRS("+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0 ")
  coordinates(corners) = c("X","Y")
  proj4string(corners) = CRS("+proj=longlat +daum=WGS84")  
  corners_utm = spTransform(corners,portal_crs)
  
  # look at the cutout box, relative to the corners of the site
  plot(portal_box)
  plot(corners_utm,add=T)
}


#' @title extract and mask raster
#' @description extracts raster files from compressed files, crops to Portal, and masks with pixel_qa layer
#'
#' @param prodID landsat product ID
#' @param tarfolder folder containing compressed files
#' @param targetpath path where the cropped and masked rasters are to be stored
#'
extract_and_mask_raster = function(prodID,tarfolder,targetpath) {
  # scene identifier: YYYYMMDD
  fid = substr(prodID,18,25)
  # which satellite
  landsat_num = as.integer(substr(prodID,4,4))
  # find the right compressed file
  tarfiles = list.files(tarfolder)
  tarfile = grep(fid,tarfiles,value=T)
  # extract ndvi and pixel_qa rasters
  pixqa_file = paste0(prodID,'_pixel_qa.tif')
  scene_file = paste0(prodID,'_sr_ndvi.tif')
  untar(paste(tarfolder,'/',tarfile,sep=''),
        exdir = targetpath,
        files = c(pixqa_file, scene_file))
  # create portal box object (1.125km from center in all directions) for cropping
  portal_box = create_portal_box()
  
  # read in raster files; crop to portal_box; delete full-size raster files  
  r = raster(paste0(targetpath,"/",scene_file))
  scene = crop(r,portal_box) 
  file.remove(paste0(targetpath,"/",scene_file))
  
  m = raster(paste0(targetpath,"/",pixqa_file))
  pixqa = crop(m,portal_box)
  file.remove(paste0(targetpath,"/",pixqa_file))
  
  # mask ndvi data; write masked raster to file
  s = mask_landsat(scene, pixelqa, landsat_num)
  return(s)
}

#' @description function to mask landsat scene
#' 
#' @param scene raster of scene to be masked
#' @param pixelqa raster of pixel QA info
#' @param landsat_num which satellite scene is from: 4,5,7,8
mask_landsat = function(scene, pixelqa, landsat_num) {
  # which landsat satellite data is from determins what the "clear" values of pixel_qa are
  # landsat8: from https://landsat.usgs.gov/sites/default/files/documents/lasrc_product_guide.pdf page 21
  # landsat 4-7: https://landsat.usgs.gov/landsat-surface-reflectance-quality-assessment
  if (landsat_num == 8) {
    clearvalues = c(322, 386, 834, 898, 1346)
  }
  else if (landsat_num %in% c(4,5,7)) {
    clearvalues = c(66, 130)
  }
  
  pixqa[!(pixqa %in% clearvalues)]=NA
  s = mask(scene,pixqa)
  writeRaster(s,paste0(targetpath,"/",prodID,'_ndvi_masked.tif'))
}


#' @title summarize_ndvi_snapshot  
#' @description summarize data for list of landsat scenes, save in csv
#' 
#' @param prodID Landsat Product Identifier
#' 
#' @return data frame of one row: contains summary statistics for single raster image
#' 
summarize_ndvi_snapshot = function(prodID) {
  # this function takes a raster of ndvi data and summarizess
  
  sat = as.character(substr(prodID,4,4))
  yr = as.integer(substr(prodID,18,21))
  mo = as.integer(substr(prodID,22,23))
  dy = as.integer(substr(prodID,24,25))
  
  r = raster(paste0(targetpath,"/",prodID,'_ndvi_masked.tif'))
  # apply correction factor
  r = r/10000
  # cloud cover
  pct = sum(is.na(values(r)))/length(values(r))*100
  
  stdev = sd(values(r),na.rm=T)
  mn = mean(values(r),na.rm=T)
  md = median(values(r),na.rm=T)
  mi = min(values(r),na.rm=T)
  ma = max(values(r),na.rm=T)
  va = var(values(r),na.rm=T)
  pix = length(values(r))
  
  d = data.frame(prodID=prodID,satellite=sat,year=yr,month=mo,day=dy,
                 stdev=stdev,mean=mn,median=md,min=mi,max=ma,
                 variance=va,numpixels=pix,pctcloud=pct)
  return(d)
}



#==========================================================================
# Run code

# place where the compressed downloaded files are
tarfolder = 'D:/Landsat7'

# place where you want the cropped and masked files to go
targetpath = 'D:/Cropped_rasters'

# look at box and corners of site
#portal_box = create_portal_box()
#plot_portal_box(portal_box)


# -----------------------------------------------------------------------
# unzip files; crop; mask using pixel QA layer; save to Cropped_rasters folder

# make a file list from the Landsat Product Identifier -- this master csv should live in the repo?
allfiles = read.csv('D:/LANDSAT_files.csv',head=T,stringsAsFactors = F)
allfiles = filter(allfiles,Spacecraft.Identifier=='ON')
filelist = allfiles$Landsat.Product.Identifier

finishedfiles = list.files(targetpath)

for (prodID in filelist) {
  print(prodID)
  # check if prodID has already been processed; if not, process it
  if (!(paste0(prodID,'_ndvi_masked.tif') %in% finishedfiles)) {
    # Extract desired files from downloaded .tar files
    extract_and_mask_raster(prodID,tarfolder,targetpath)
  }
}


# ----------------------------------------------------------------------------------------------
# summarize; write csv

# if LandsatNDVI_raw.csv does not already exist, initialize data frame:
#data = data.frame(prodID=as.character(),satellite=as.character(),year=as.integer(),month=as.integer(),
#                  day=as.integer(),stdev=as.numeric(),mean=as.numeric(),median=as.numeric(),min=as.numeric(),
#                  max=as.numeric(),variance=as.numeric(),numpixels=as.numeric(),pctcloud=as.numeric())


# if it does, read in existing version of raw landsat data
data = read.csv('../NDVI/LandsatNDVI_raw.csv')

data_modified <- data
for (prodID in filelist) {
  # if prodID is not already in the existing version of the data, summarize and append
  if (!(prodID %in% data$prodID)) {
    d = summarize_ndvi_snapshot(prodID)
    data_modified = rbind(data_modified,d)
  } 
}
# put in chronological order
data_modified = data_modified[with(data_modified,order(year,month,day)),]


# write to file if anything was added
if (dim(data_modified)[1] > dim(data)[1]) {
  write.csv(data,file='../NDVI/LandsatNDVI_raw.csv',row.names=F)
}

