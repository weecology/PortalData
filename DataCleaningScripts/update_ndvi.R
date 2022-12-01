# Adapted for automated updating from get_landsat_data.R
# Rewritten for new USGS/EROS api
# https://www.usgs.gov/landsat-missions/landsat-collection-2-level-2-science-products

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
  portal_area_transform <- suppressWarnings(as(sf::st_buffer(center_transform, 1000, ), 'Spatial'))
  portal_area <- sp::spTransform(portal_area_transform, sp::CRS("+proj=utm +zone=12
                     +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0 "))
  return(portal_area)
  
}

#' @title extract and mask raster
#' @description extracts raster files from compressed files, crops to Portal,
#' and masks with pixel_qa layer
#'
#' @param records new records to be used
#' @param targetpath path where the cropped and masked rasters are to be stored
#'
extract_and_mask_raster <- function(records, targetpath = tempdir()) {
  
  # create portal box object for cropping
  portal_area <- create_portal_area()
  
  # read in raster files; crop to portal_box; apply scaling factor and offset; delete full-size raster files
  # In Landsat 8-9, NDVI = (Band 5 – Band 4) / (Band 5 + Band 4).
  B4 <- raster::raster(paste0(targetpath,"/", records["display_id"], "_SR_B4.TIF")) %>%
    raster::crop(portal_area) * 0.0000275 + -0.2
  B5 <- raster::raster(paste0(targetpath,"/", records["display_id"], "_SR_B5.TIF")) %>%
    raster::crop(portal_area) * 0.0000275 + -0.2
  
  sr_ndvi <- (B5 - B4)/(B5 + B4)
  
  pixelqa <- raster::raster(paste0(targetpath,"/", records["display_id"], "_QA_PIXEL.TIF")) %>%
    raster::crop(portal_area)
  
  # mask ndvi data
  # "clear" values of pixel_qa are derived from the CFMask algorithm version 3.3.1
  # https://www.usgs.gov/media/files/landsat-8-9-collection-2-level-2-science-product-guide
  clearvalues = c(21824, 21826, 22080, 23888, 30048, 54596, 54852)
  
  pixelqa[!(pixelqa %in% clearvalues)] <- NA
  ndvi_masked <- raster::mask(x=sr_ndvi, mask=pixelqa)
  # raster::writeRaster(s,paste0(targetpath,"/", record_id,'_ndvi_masked.tif'), overwrite=TRUE)
  
  return(ndvi_masked)
}

#' @title summarize_ndvi_snapshot
#' @description summarize data for list of landsat scenes, save in csv
#'
#' @param records new records to be used
#' @param targetpath path where the cropped and masked rasters are to be stored
#'
#' @return data frame of one row: contains summary statistics for single raster image
#'
summarize_ndvi_snapshot <- function(records, targetpath = tempdir()) {
  # this function takes a raster of ndvi data and summarizes
  print(records["display_id"])
  source <- "USGS"
  sensor <- paste0("Landsat", records["satellite"])
  date <- as.Date(records["acquisition_date"])
  
  r <- extract_and_mask_raster(records, targetpath)
  
  # cloud cover
  pct <- sum(is.na(values(r)))/length(values(r))*100
  
  stdev <- sd(values(r),na.rm=T)
  mn <- mean(values(r),na.rm=T)
  md <- median(values(r),na.rm=T)
  mi <- min(values(r),na.rm=T)
  ma <- max(values(r),na.rm=T)
  va <- var(values(r),na.rm=T)
  pix <- length(values(r))
  
  d <- data.frame(date = as.Date(date), sensor = sensor, source = source,
                  pixel_count = pix, ndvi = ifelse(!is.finite(mn),NA,mn), cloud_cover = pct,
                  var = ifelse(!is.finite(va),NA,va), min = ifelse(!is.finite(mi),NA,mi),
                  max = ifelse(!is.finite(ma),NA,ma))
  return(d)
}

#' @title writendvitable
#' @description get new ndvi data and write to ndvi table
#'
#'
#'

writendvitable <- function() {
  
  if(file.exists("./NDVI/scenes.csv")) {
    if(file.size("./NDVI/scenes.csv") != 0L) {
  targetpath <- "./NDVI/landsat-data"
  undone <- read.csv("./NDVI/undone-scenes.csv")
  records <- read.csv("./NDVI/scenes.csv") %>% dplyr::filter(!display_id %in% undone$display_id)
    
    new_data <- as.data.frame(do.call(rbind, 
                                      apply(records, 1, summarize_ndvi_snapshot, targetpath))) %>%
      dplyr::arrange(date,sensor)
    
    write.table(new_data, file='./NDVI/ndvi.csv', sep = ",", row.names=FALSE, col.names=FALSE,
                append=TRUE, na="")
  }}
}
