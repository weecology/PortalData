library(datamodelr)

surveys = read.csv("Rodents/Portal_rodent.csv", stringsAsFactors = FALSE)
plots = read.csv("SiteandMethods/Portal_plots.csv", stringsAsFactors = FALSE)
species = read.csv("Rodents/Portal_rodent_species.csv", stringsAsFactors = FALSE)

# Can't currently get both proper arrow direction and both arrows to show
#dm <- dm_add_references(datamod, species$speciescode == surveys$species, plots$plot == surveys$plot)
dm <- dm_add_references(datamod, surveys$species == species$speciescode, surveys$plot == plots$plot)

table_segments <- list(
    Rodents = c("surveys", "species"),
    Site = c("plots")
)
dm <- dm_set_segment(dm, table_segments)

display <- list(
  accent1 = c("surveys", "species"),
  accent2 = c("plots")
)
dm <- dm_set_display(dm, display)

dm_graph = dm_create_graph(dm, rankdir = "RL", col_attr = c("column", "type"))
dm_render_graph(dm_graph)
dm_export_graph(graph = dm_graph, file_name="schema.png")
 
#New packages needed for dm_export_graph w/svg:
#rsvg (w/librsvg2-dev dep on debian), V8
