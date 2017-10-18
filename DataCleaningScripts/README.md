# Guide to Portal Data Cleaning Procedures

This includes scripts used to clean new Portal data before they are appended to the relevant data table. It also includes functions sourced by continuous integration to update supplementary data tables. Unit tests are run on all active (still receiving new data) data tables and functions with every addition of new data (in [testthat](../testthat)).

### Rodent Data
1. [Compare double-entered data](compare_raw_data.r)

2. [Quality control](rodent_data_cleaning_functions.R)

    -[check for all plots present](check_all_plots_present.r)

    -check for appropriate dates

    -compare tag data to reader tag numbers

    -check body size measurements against Species

    -check reproductive status against sex

    -flag missing data

    -flag duplicate stakes

    -add R to all removed rodents

3. Correct recaptures

    -add 'new tag' * to all new captures

    -check for consistent species and sex on recaptures

4. Append new data to table, write table to file

### Plant Data

#### Abundance Quadrats
1. [Compare double-entered data](compare_raw_data.r)

2. [Quality Control](clean_plant_quadrat_data.R)

    -[check for all plots present](check_all_plots_present.r)

    -check for all quadrats present

    -confirm all species in species list, add new species to species list

    -check for duplicate species on quadrat

    -flag missing values

3.Remove empty quadrats, append data to table, write table to file

#### Shrub Transects
1. [Compare double-entered data](compare_raw_data.r)

2. [Quality Control](clean_shrub_transect_data.R)

    -[check for all plots present](check_all_plots_present.r)

    -check for all transects present

    -confirm all species in species list, add new species to species list

    -flag missing values

3.Remove empty quadrats, append data to table, write table to file

### Done through Continuous Integration

#### Weather Data
[new_weather_data](new_weather_data.R)

1. Quality Control

    -dates align with previous data

    -check data range on temperature, relhumid, precip

    -check battery voltage

2. Append new data, write table to file


#### Update rodent trapping table with latest census info
[update_portal_rodent_trapping](update_portal_rodent_trapping.r)

#### Update plot table to current date
[update_portal_plots](update_portal_plots.R)

#### Update Moon number table with latest census info
[new_moon_numbers](new_moon_numbers.r)

#### Update plant census table with latest census info
[update_portal_plant_censuses](update_portal_plant_censuses.R)


	