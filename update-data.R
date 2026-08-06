message("Updating regional weather data")
source("DataCleaningScripts/get_regional_weather.R"); append_regional_weather()

message("Updating weather station data")
source("DataCleaningScripts/new_weather_data.R"); append_weather()

message("Updating Rodent trapping table")
source("DataCleaningScripts/update_portal_rodent_trapping.r"); writetrappingtable()

message("Updating Plots table")
source("DataCleaningScripts/update_portal_plots.R"); writeportalplots()

message("Updating New Moon Numbers")
source("DataCleaningScripts/new_moon_numbers.r"); writenewmoons()

message("Updating Plant census table")
source("DataCleaningScripts/update_portal_plant_censuses.R"); writecensustable()

message("Updating NDVI")
deepforest_python <- "/opt/miniconda3/envs/deepforest/bin/python"
python <- if (file.exists(deepforest_python)) deepforest_python else "python3"
output <- system2(python, "DataCleaningScripts/NDVI.py", stderr = TRUE, stdout = TRUE)
# Check if the Python script returns an error
if (!is.null(attr(output, "status")) && attr(output, "status") != 0) {
stop("Error in NDVI.py:\n", paste(output, collapse = "\n"))
}
message("NDVI download completed successfully.")

source("DataCleaningScripts/update_ndvi.R")
ndvi_updated <- writendvitable()
if (isTRUE(ndvi_updated)) {
  message("NDVI table updated with processed scenes.")
  system("rm -r ./NDVI/landsat-data ./NDVI/scenes.csv")
} else {
  message("NDVI table not updated (no processed scenes). Leaving download artifacts for retry.")
}