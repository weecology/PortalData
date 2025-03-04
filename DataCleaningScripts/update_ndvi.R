# Adapted for automated updating from get_landsat_data.R
# Rewritten for new USGS/EROS api
# https://www.usgs.gov/landsat-missions/landsat-collection-2-level-2-science-products

# Load required libraries with consistent formatting
`%>%` <- magrittr::`%>%`
suppressPackageStartupMessages({
  library(terra, warn.conflicts = FALSE, quietly = TRUE)
  library(dplyr)
  library(stringr)
  library(lubridate)
})

#==============================================================================
# Configuration
#==============================================================================

# Define constants
PORTAL_CENTER <- c(-109.08029, 31.937769)
PORTAL_RADIUS <- 1000 # in meters
LANDSAT_DIR <- "./NDVI/landsat-data"
SCENES_CSV <- "./NDVI/scenes.csv"
UNDONE_SCENES_CSV <- "./NDVI/undone-scenes.csv"
NDVI_CSV <- "./NDVI/ndvi.csv"

# Clear pixel values from CFMask algorithm version 3.3.1
# https://www.usgs.gov/media/files/landsat-8-9-collection-2-level-2-science-product-guide
CLEAR_PIXEL_VALUES <- c(21824, 21826, 22080, 23888, 30048, 54596, 54852)

# Scaling factors for Landsat data
SCALE_FACTOR <- 0.0000275
SCALE_OFFSET <- -0.2

#==============================================================================
# Spatial processing functions
#==============================================================================

#' Create a circular spatial polygon for the Portal study area
#'
#' @param centroid Vector of coordinates in lon/lat of center of area [lon,lat]
#' @param radius Desired radius, in meters
#' @return A SpatialPolygons object that can be used for cropping rasters
#'
#' @examples
#' portal_area <- create_portal_area()
create_portal_area <- function(centroid = PORTAL_CENTER, radius = PORTAL_RADIUS) {
  # Create point and transform to appropriate CRS
  center <- sf::st_sfc(sf::st_point(centroid), crs = "WGS84")
  center_transform <- sf::st_as_sf(center) %>% sf::st_transform(3488)

  # Create buffer and transform to UTM
  portal_area_transform <- suppressWarnings(
    as(sf::st_buffer(center_transform, radius), 'Spatial')
  )

  # Transform to UTM
  portal_area <- sp::spTransform(
    portal_area_transform,
    sp::CRS(
      "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0"
    )
  )

  return(portal_area)
}

#' Load and process a Landsat raster band
#'
#' @param file_path Path to the band file
#' @param portal_area Portal area polygon for cropping
#' @param apply_scaling Whether to apply scaling factor and offset
#' @return Processed raster
load_and_process_band <- function(file_path, portal_area, apply_scaling = TRUE) {
  # Check if file exists
  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }

  # Load and crop raster
  band <- terra::rast(file_path) %>% terra::crop(portal_area)

  # Apply scaling if requested
  if (apply_scaling) {
    band <- band * SCALE_FACTOR + SCALE_OFFSET
  }

  return(band)
}

#' Extract and mask raster data for NDVI calculation
#'
#' @param records Record containing scene information
#' @param targetpath Path where the raster files are stored
#' @return Masked NDVI raster
extract_and_mask_raster <- function(records, targetpath = tempdir()) {
  # Create portal area for cropping
  portal_area <- create_portal_area()

  # Build file paths
  scene_id <- records["displayId"]
  b4_path <- file.path(targetpath, paste0(scene_id, "_SR_B4.TIF"))
  b5_path <- file.path(targetpath, paste0(scene_id, "_SR_B5.TIF"))
  qa_path <- file.path(targetpath, paste0(scene_id, "_QA_PIXEL.TIF"))

  # Load and process bands
  tryCatch({
    B4 <- load_and_process_band(b4_path, portal_area)
    B5 <- load_and_process_band(b5_path, portal_area)
    pixelqa <- load_and_process_band(qa_path, portal_area, apply_scaling = FALSE)

    # Calculate NDVI
    sr_ndvi <- (B5 - B4) / (B5 + B4)

    # Mask non-clear pixels
    pixelqa[!(pixelqa %in% CLEAR_PIXEL_VALUES)] <- NA
    ndvi_masked <- terra::mask(x = sr_ndvi, mask = pixelqa)

    # Add this check
    if (all(is.na(values(ndvi_masked)))) {
      message(paste("Warning: Scene", scene_id, "has no valid NDVI values after masking. This may indicate 100% cloud cover or other quality issues."))
    }

    return(ndvi_masked)
  }, 
  error = function(e) {
    message(paste("Error processing scene", scene_id, ":", e$message))
    # Return empty raster with same extent as portal area
    return(NULL)
  })
}

#==============================================================================
# Date handling functions
#==============================================================================

#' Parse date string with multiple format attempts
#'
#' @param date_str Date string to parse
#' @return Parsed Date object or NA if parsing fails
parse_date <- function(date_str) {
  # Try common date formats
  date_formats <- c(
    "%Y-%m-%d",  # ISO format: 2025-01-29
    "%Y/%m/%d",  # 2025/01/29
    "%m/%d/%Y"   # 01/29/2025
  )

  for (format in date_formats) {
    date <- try(as.Date(date_str, format = format), silent = TRUE)
    if (!inherits(date, "try-error") && !is.na(date)) {
      return(date)
    }
  }

  # If all parsing attempts fail, log warning and use current date
  warning(paste("Could not parse date:", date_str, "- using current date instead"))
  return(Sys.Date())
}

#==============================================================================
# NDVI processing functions
#==============================================================================

#' Calculate summary statistics for NDVI raster
#'
#' @param raster NDVI raster
#' @return Named list of statistics
calculate_ndvi_stats <- function(raster) {
  # Handle NULL raster case
  if (is.null(raster)) {
    return(list(
      ndvi = NA, 
      cloud_cover = 100,
      var = NA,
      min = NA,
      max = NA,
      pixel_count = 0
    ))
  }

  # Extract values
  vals <- values(raster)

  # Check if we have any non-NA values
  if (all(is.na(vals)) || length(vals[!is.na(vals)]) == 0) {
    return(list(
      ndvi = NA,
      cloud_cover = 100,
      var = NA,
      min = NA,
      max = NA,
      pixel_count = length(vals)
    ))
  }

  # Calculate statistics
  stats <- list(
    ndvi = mean(vals, na.rm = TRUE),
    cloud_cover = sum(is.na(vals)) / length(vals) * 100,
    var = if(length(vals[!is.na(vals)]) > 1) var(vals, na.rm = TRUE)[1, 1] else NA,
    min = min(vals, na.rm = TRUE),
    max = max(vals, na.rm = TRUE),
    pixel_count = length(vals)
  )

  # Handle non-finite values
  for (name in c("ndvi", "var", "min", "max")) {
    if (!is.finite(stats[[name]])) {
      stats[[name]] <- NA
    }
  }

  return(stats)
}

#' Summarize NDVI data for a single Landsat scene
#'
#' @param records Record with scene information
#' @param targetpath Path where the raster files are stored
#' @return Data frame with summary statistics
summarize_ndvi_snapshot <- function(records, targetpath = tempdir()) {
  # Log processing
  scene_id <- records["displayId"]
  message(paste("Processing scene:", scene_id))

  # Extract metadata
  source <- "USGS"
  sensor <- paste0("Landsat", records["satellite"])
  date <- parse_date(records["date_acquired"])

  # Process raster data
  r <- extract_and_mask_raster(records, targetpath)

  # Calculate statistics
  stats <- calculate_ndvi_stats(r)

  # Create data frame with results
  d <- data.frame(
    date = date,
    sensor = sensor,
    source = source,
    pixel_count = stats$pixel_count,
    ndvi = stats$ndvi,
    cloud_cover = stats$cloud_cover,
    var = stats$var,
    min = stats$min,
    max = stats$max
  )

  return(d)
}

#==============================================================================
# Main functions
#==============================================================================

#' Check if a file exists and is not empty
#'
#' @param file_path Path to the file
#' @return TRUE if file exists and is not empty, FALSE otherwise
file_exists_and_not_empty <- function(file_path) {
  return(file.exists(file_path) && file.size(file_path) > 0)
}

#' Read CSV file with error handling
#'
#' @param file_path Path to the CSV file
#' @param default Default value to return if file can't be read
#' @return Data frame with CSV contents or default value
read_csv_safe <- function(file_path, default = data.frame()) {
  if (file_exists_and_not_empty(file_path)) {
    tryCatch({
      return(read.csv(file_path, stringsAsFactors = FALSE))
    }, error = function(e) {
      warning(paste("Failed to read", file_path, ":", e$message))
      return(default)
    })
  }
  return(default)
}

#' Get new NDVI data and write to NDVI table
#'
#' @return Invisibly returns TRUE if processing completed, FALSE otherwise
writendvitable <- function() {
  # Check if input data exists
  if (!file_exists_and_not_empty(SCENES_CSV)) {
    message("No scenes.csv file found or file is empty. Skipping NDVI processing.")
    return(invisible(FALSE))
  }

  # Set up data directory
  targetpath <- LANDSAT_DIR
  dir.create(targetpath, showWarnings = FALSE, recursive = TRUE)

  # Read input data
  undone <- read_csv_safe(UNDONE_SCENES_CSV, data.frame(displayId = character(0)))
  scenes <- read_csv_safe(SCENES_CSV)

  # Filter scenes - exclude those in undone list
  records <- scenes %>%
    filter(!sapply(displayId, function(id) {
      any(str_detect(undone$displayId, fixed(id)))
    }))

  # Skip if no records to process
  if (nrow(records) == 0) {
    message("No new scenes to process.")
    return(invisible(FALSE))
  }

  # Process all records
  message(paste("Processing", nrow(records), "scenes..."))

  new_data <- tryCatch({
    # Apply processing to each record
    results <- apply(records, 1, summarize_ndvi_snapshot, targetpath = targetpath)

    # Combine results and sort
    as.data.frame(do.call(rbind, results)) %>%
      dplyr::arrange(date, sensor)
  },
  error = function(e) {
    message(paste("Error processing scenes:", e$message))
    return(NULL)
  })

  # Save results if processing succeeded
  if (!is.null(new_data) && nrow(new_data) > 0) {
    # Ensure directory exists
    dir.create(dirname(NDVI_CSV), showWarnings = FALSE, recursive = TRUE)

    # Determine if file exists to handle headers correctly
    file_exists <- file.exists(NDVI_CSV)

    # Write data
    write.table(
      new_data,
      file = NDVI_CSV,
      sep = ",",
      row.names = FALSE,
      col.names = !file_exists,  # Include header only if file doesn't exist
      append = file_exists,      # Append if file exists
      na = ""
    )

    message(paste("Added", nrow(new_data), "new NDVI records."))
    return(invisible(TRUE))
  } else {
    message("No new NDVI data to add.")
    return(invisible(FALSE))
  }
}

# If script is run directly (not sourced), execute the main function
if (!interactive() && identical(sys.nframe(), 0L)) {
  writendvitable()
}
