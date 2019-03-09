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