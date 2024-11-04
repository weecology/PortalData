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

# message("Updating NDVI")
# exit_status <- system2("python3", args = "DataCleaningScripts/NDVI.py", stderr = TRUE, stdout = TRUE)
# if (exit_status != 0) {
#   stop("Error: The Python script 'NDVI.py' failed to execute.")
# }

message("Updating NDVI")
output <- system2("python3", "DataCleaningScripts/NDVI.py", stderr = TRUE, stdout = TRUE)

if ((status <- attr(output, "status")) != 0) stop("Error in NDVI.py:\n", paste(output, collapse = "\n"))
message("NDVI update completed successfully.")

source("DataCleaningScripts/update_ndvi.R"); writendvitable()
system("rm -r ./NDVI/landsat-data ./NDVI/scenes.csv")
