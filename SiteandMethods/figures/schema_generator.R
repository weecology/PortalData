library(datamodelr)

#Site
plots = read.csv("../SiteandMethods/Portal_plots.csv", stringsAsFactors = FALSE)
coordinates = read.csv("../SiteandMethods/Portal_UTMcoords.csv", stringsAsFactors = FALSE)

#Rodents
surveys = read.csv("../Rodents/Portal_rodent.csv", stringsAsFactors = FALSE)
species = read.csv("../Rodents/Portal_rodent_species.csv", stringsAsFactors = FALSE)
newmoondates = read.csv("../Rodents/moon_dates.csv", stringsAsFactors = FALSE)
trapping = read.csv("../Rodents/Portal_rodent_trapping.csv", stringsAsFactors = FALSE)

#Plants
censuses = read.csv("../Plants/Portal_plant_censuses.csv", stringsAsFactors = FALSE)
quadrats = read.csv("../Plants/Portal_plant_quadrats.csv", stringsAsFactors = FALSE)
transects = read.csv("../Plants/Portal_plant_transects_2015_present.csv", stringsAsFactors = FALSE)
plantspecies = read.csv("../Plants/Portal_plant_species.csv", stringsAsFactors = FALSE)

#Ants
abundance = read.csv("../Ants/Portal_ant_bait.csv", stringsAsFactors = FALSE)
colonies = read.csv("../Ants/Portal_ant_colony.csv", stringsAsFactors = FALSE)
antspecies = read.csv("../Ants/Portal_ant_species.csv", stringsAsFactors = FALSE)

#Weather
weather = read.csv("../Weather/Portal_weather.csv", stringsAsFactors = FALSE)
dailyweather = read.csv("../Weather/Portal_weather_19801989.csv", stringsAsFactors = FALSE)
storms = read.csv("../Weather/Portal_storms.csv", stringsAsFactors = FALSE)

datamod <- dm_from_data_frames(plots, coordinates, surveys, species, newmoondates, trapping, censuses, 
                               quadrats, transects, plantspecies, abundance, colonies, antspecies, 
                               weather, dailyweather, storms)

# Can't currently get both proper arrow direction and both arrows to show
#dm <- dm_add_references(datamod, species$speciescode == surveys$species, plots$plot == surveys$plot)
dm <- dm_add_references(datamod, plots$plot == coordinates$plot, surveys$species == species$speciescode, 
                        surveys$plot == plots$plot, trapping$plot == plots$plot, 
                        newmoondates$period == surveys$period, quadrats$species == plantspecies$speciescode,
                        transects$species == plantspecies$speciescode, quadrats$plot == plots$plot,
                        transects$plot == plots$plot, censuses$plot == plots$plot, 
                        censuses$plot == quadrats$plot, censuses$quadrat == quadrats$quadrat,
                        abundance$plot == plots$plot, colonies$plot == plots$plot, 
                        abundance$species == antspecies$speciescode, colonies$species == antspecies$speciescode,
                        weather$year == plots$year, weather$month == plots$month)

table_segments <- list(
  Site = c("plots","coordinates"),  
  Rodents = c("surveys", "species", "newmoondates", "trapping"),
  Plants = c("censuses", "quadrats", "transects", "plantspecies"),
  Ants = c("abundance", "colonies", "antspecies"),
  Weather = c("weather", "dailyweather", "storms")
)

dm <- dm_set_segment(dm, table_segments)

display <- list(
  accent1 = c("plots","coordinates"),  
  accent2 = c("surveys", "species", "newmoondates", "trapping"),
  accent3 = c("censuses", "quadrats", "transects", "plantspecies"),
  accent4 = c("abundance", "colonies", "antspecies"),
  accent5 = c("weather", "dailyweather", "storms")
)
dm <- dm_set_display(dm, display)

dm_graph = dm_create_graph(dm, rankdir = "BT", view_type = "keys_only")
dm_render_graph(dm_graph)

#Rodent sub-schema
focus <- list(
  tables = c("plots","surveys", "species", "newmoondates", "trapping"))
dm_graph = dm_create_graph(dm, rankdir = "RL", col_attr = c("column", "type"), focus = focus)
dm_render_graph(dm_graph)

#Plant sub-schema
focus <- list(
  tables = c("plots","censuses", "quadrats", "transects", "plantspecies"))
dm_graph = dm_create_graph(dm, rankdir = "RL", col_attr = c("column", "type"), focus = focus)
dm_render_graph(dm_graph)

#Ant sub-schema
focus <- list(
  tables = c("plots","abundance", "colonies", "antspecies"))
dm_graph = dm_create_graph(dm, rankdir = "RL", col_attr = c("column", "type"), focus = focus)
dm_render_graph(dm_graph)

#Ant sub-schema
focus <- list(
  tables = c("weather", "dailyweather", "storms"))
dm_graph = dm_create_graph(dm, rankdir = "BT", col_attr = c("column", "type"), focus = focus)
dm_render_graph(dm_graph)


dm_export_graph(graph = dm_graph, file_name="schema.png")
 
#New packages needed for dm_export_graph w/svg:
#rsvg (w/librsvg2-dev dep on debian), V8
