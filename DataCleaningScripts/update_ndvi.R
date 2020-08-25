# Adapted for automated updating from get_landsat_data.R

`%>%` <- magrittr::`%>%`
library(raster)

#' @title create_portal_area
#' 
#' @description creates a circular SpatialPolygons object centered at a given lon/lat point and a 
#' given radius from that point.
#'              CRS must be specified
#'              center of Portal: 31.937769, -109.08029
#'              corners of Portal: NW = 31.939568, -109.083177
#'                    NE = 31.939569, -109.077460
#'                    SW = 31.935860, -109.082948
#'                    SE = 31.935948, -109.077317
#' 
#' @param centroid vector of coordinates in lon/lat of center of box [lon,lat]
#' @param radius desired radius, in m
#' 
#' @return portal_area is a SpatialPolygons object that can be used for cropping rasters
#' 
#' @example create_portal_area(centroid = c(-109.08029, 31.937769), radius = 1125)
#' 
create_portal_area <- function(centroid = c(-109.08029, 31.937769), 
                             radius = 1000) {
  
  center <- sf::st_sfc(sf::st_point(centroid),crs="WGS84")
  #transform to NAD83(NSRS2007)/California Albers
  center_transform <- sf::st_as_sf(center) %>% sf::st_transform(3488) 
  portal_area_transform <- as(sf::st_buffer(center_transform, 1000), 'Spatial')
  portal_area <- sp::spTransform(portal_area_transform, sp::CRS("+proj=utm +zone=12 
                     +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0 "))
  return(portal_area)
  
}


#' Fetch new ndvi and put in new data order via getSpatialData
#' 
#' @param mindate minimum date to collect
#' @param maxdate maximum date to collect
#' @param targetpath path for data downloads 
#'

new_records <- function(mindate, maxdate, targetpath = tempdir()) {

getSpatialData::set_archive(targetpath)
getSpatialData::set_aoi(create_portal_area())
getSpatialData::login_USGS(username = "weecology", password = Sys.getenv("USGS_PASSWORD"))

records <- getSpatialData::get_records(time_range = c(mindate, maxdate),
                                       products = "LANDSAT_8_C1")
records <- records[records$level == "sr_ndvi",]
records <- getSpatialData::check_availability(records)
records <- getSpatialData::get_data(records)

# Submit order for any new records not downloaded
records <- getSpatialData::order_data(records)

return(records)
}

#' @title extract and mask raster
#' @description extracts raster files from compressed files, crops to Portal, 
#' and masks with pixel_qa layer
#'
#' @param records new records to be used
#' @param targetpath path where the cropped and masked rasters are to be stored
#'
extract_and_mask_raster <- function(records, targetpath = tempdir()) {
  tarfile <- as.character(unlist(records["dataset_file"]))[1]
  record_id <- as.character(unlist(records["record_id"]))[1]
  # extract ndvi and pixel_qa rasters
  untar(tarfile, exdir = targetpath)
  # create portal box object for cropping
  portal_area <- create_portal_area()
  
  # read in raster files; crop to portal_box; delete full-size raster files  
  r <- raster::raster(paste0(targetpath,"/", record_id, "_sr_ndvi.tif"))
  scene <- raster::crop(r,portal_area)
  
  m <- raster::raster(paste0(targetpath,"/", record_id, "_pixel_qa.tif"))
  pixelqa <- raster::crop(m,portal_area)
  
  # mask ndvi data; write masked raster to file
  s <- mask_landsat(record_id, scene, pixelqa)
  return(s)
}

#' @description function to mask landsat scene
#' 
#' @param record_id new record to be used
#' @param scene raster of scene to be masked
#' @param pixelqa raster of pixel QA info
#' 

mask_landsat <- function(record_id, scene, pixelqa) {
  
  # which landsat satellite data is from determins what the "clear" values of pixel_qa are
  # landsat8: from https://landsat.usgs.gov/sites/default/files/documents/lasrc_product_guide.pdf page 21
  clearvalues = c(322, 386, 834, 898, 1346)
  
  pixelqa[!(pixelqa %in% clearvalues)] <- NA
  s <- raster::mask(x=scene, mask=pixelqa)
  raster::writeRaster(s,paste0(targetpath,"/", record_id,'_ndvi_masked.tif'), overwrite=TRUE)
}


#' @title summarize_ndvi_snapshot  
#' @description summarize data for list of landsat scenes, save in csv
#' 
#' @param records new records to be used
#' 
#' @return data frame of one row: contains summary statistics for single raster image
#' 
summarize_ndvi_snapshot <- function(records) {
  # this function takes a raster of ndvi data and summarizess
  
  source <- "AWS"
  sensor <- "Landsat8"
  date <- as.Date(records$date_acquisition)
  
  r = raster(paste0(targetpath,"/",records$record_id,'_ndvi_masked.tif'))
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
  
  d = data.frame(date = date, sensor = sensor, source = source,
                 pixel_count = pix, ndvi = mn)
  return(d)
}

#' @title writendvitable  
#' @description get new ndvi data and write to ndvi table
#' 
#'
#' 

writendvitable <- function() {
  
ndvi <- read.csv("../NDVI/ndvi.csv")
mindate <- as.character(max(as.Date(ndvi$date))+1)
maxdate <- as.character(Sys.Date())
targetpath <- tempdir()
records <- new_records(mindate, maxdate, targetpath)

for(i in 1:dim(records)[1]) {
extract_and_mask_raster(records[i,],targetpath) }
 

new_data <- as.data.frame(do.call(rbind, apply(records,1,summarize_ndvi_snapshot)))
write.table(new_data, file='./NDVI/ndvi.csv', sep = ",", row.names=FALSE, col.names=FALSE, 
            append=TRUE, na="")

}
