library(dplyr)
currentdir = getwd()

if(substr(currentdir, nchar(currentdir) - 8, nchar(currentdir)) == '/testthat') {
  source('../DataCleaningScripts/general_data_cleaning_functions.R')
} else {
  source('DataCleaningScripts/general_data_cleaning_functions.R')
}


#' @title quadrat data quality check
#'
#' @param df data frame of plant quadrat data (loaded from excel file of entered data)
#' @param splist data frame of Portal_plant_species.csv: contains column speciescode
#'
quadrat_data_quality_checks = function(df,splist) {
  # find species not in species list
  sp_check = check_species(df,splist$speciescode)
  if (length(sp_check)>0) {print('species not in species list:')
    print(sp_check)}
  
  # check for illegal quadrat number
  quads = c(11,13,15,17,31,33,35,37,51,53,55,57,71,73,75,77)
  badquads = ws[!(ws$quadrat %in% quads),]
  if (length(badquads)>0) {print('bad quadrat numbers:')
    print(badquads)}
  
  # check for duplicate quadrats: i.e. same plot/quadrat/species on more than one line in data frame
  dups = duplicate_quads(ws)
  if (length(dups)>0) {print('duplicated plot/quadrat/species:')
    print(dups)}
  
  # check all quadrats present
  missingquads = all_quads(ws,plots=seq(24),quads)
  if (dim(missingquads)[1]>0) {print('missing quadrats:')
    print(missingquads)}
  
  # check that empty quadrats are handled appropriately (species=NA, abundance=0)
  emptyquad_problem = check_empty_quads(ws)
  if (length(emptyquad_problem)>0) {print('check empty quadrats:')
    print(emptyquad_problem)}
}


#' @title check species in data frame against a list of allowed species
#' 
#' @param df data frame containing "species" column
#' @param allowed_species list of allowed species
#' 
#' @return subset of original data frame, just the rows where "species" should be checked
#'
check_species = function(df,allowed_species) {
  new.names = setdiff(df$species,c(allowed_species,NA))
  return(df[df$species %in% new.names,])
}


#' @title check all quadrats present
#' @description checks that all combinations of plot and quadrat are accounted for in data (even if empty). Should be 384 unique quadrats.
#' 
#' @param df data frame of quadrat data. required column names: plot, quadrat
#' @param plots list of plots there should be (default 1:24)
#' @param quads list of quadrats there should be
#' 
#' @return data frame with plot and quadrat columns, pairs not found in data
#' 
all_quads = function(df,plots=seq(24),quads) {
  allquads <- expand.grid(plot=plots,quadrat=quads)
  plotquad <- dplyr::select(df,plot,quadrat) %>% unique()
  
  # return any plot-stake pairs that should be censused that are not in the data
  missingquads = dplyr::anti_join(allquads,plotquad,by=c('plot','quadrat')) 
  return(data.frame(missingquads))
}

#' @title check for duplicate entries based on plot, quadrat, species
#' 
#' @param df data frame of quadrat data. required column names: plot, quadrat, species
#' @return data frame of plot, quadrat, species of duplicates (with row numbers)
#'
duplicate_quads = function(df) {
  data = dplyr::select(df,plot,quadrat,species)
  duplicates = duplicated(data) | duplicated(data, fromLast = TRUE) 
  return(data[duplicates,])
}

#' @title check empty quadrats
#' @description confirm that empty quadrats are handled appropriately: i.e. if a quadrat is 
#' supposed to be empty, there isn't also a row that has data for it
#' 
#' @param df data frame of quadrat data
#'
check_empty_quads = function(df) {
  # divide df into empty quadrats and nonempty quadrats
  abund0 <-  df[df$abundance == 0,]
  emptyrows = row.names(abund0)
  empties = df[emptyrows,]
  nonempties = remove_empty_quads(df)
  
  # check for overlap between empty and nonempty
  overlap = dplyr::inner_join(empties[,c('plot','quadrat')],nonempties[,c('plot','quadrat')],by=c('plot','quadrat'))
  return(dplyr::right_join(df,overlap,by=c('plot','quadrat')))
}

#' @title remove empty quadrats
#' @description identifies empty quadrats (entered in data for qc purposes), and removes from data frame
#'              classifies quadrats as empty based on abundance = 0
#' 
#' @param df data frame of quadrat data
remove_empty_quads = function(df) {
  abund0 <- df[df$abundance == 0,]
  emptyrows = row.names(abund0)
  otherrows = row.names(df)[!(row.names(df) %in% emptyrows)]
  return(df[otherrows,])
}

#' @title transect data quality checks
#' 
#' @param df data frame of transect data
#' @param splist data frame of Portal_plant_species.csv: contains column speciescode
#'
transect_data_quality_checks = function(df,splist) {
  # find species not in species list
  sp_check = check_species(df,splist$speciescode)
  if (dim(sp_check)[1]>0) {print('species not in species list:')
    print(sp_check)}
  
  # check for illegal transect number
  transects <- c("11", "71")
  badtransects = ws[!(ws$transect %in% transects),]
  if (dim(badtransects)[1]>0) {print('bad quadrat numbers:')
    print(badtransects)}
  
  # check all transects present
  missingtransects = all_transects(df,plots=seq(24),transects=c(11,71))
  if (dim(missingtransects)[1]>0) {print('missing transects:')
    print(missingtransects)}
  
  # check for valid stop and start values (length of hypotenuse of plots (7000) plus some wiggle room)
  startstop = check_start_stop(df)
  if (dim(startstop)[1]>0) {print('check start/stop:')
    print(startstop)}
  
  # check for valid height value
  checkheight = df[which(!(df$height %in% 0:400)),]
  if (dim(checkheight)[1]>0) {print('check height:')
    print(checkheight)}

}

#' @title check all (2) transects present
#' @description checks that all combinations of plot and transect are accounted for in data (even if empty). 2 transects per plot.
#' 
#' @param df data frame of transect data. required column names: plot, transect
#' @param plots list of plots there should be (default 1:24)
#' @param transects list of transects there should be
#' 
#' @return data frame with plot and transect columns, pairs not found in data
#' 
all_transects = function(df,plots=seq(24),transects) {
  alltransects <- expand.grid(plot=plots,transect=transects)
  plottransect <- dplyr::select(df,plot,transect) %>% unique()
  
  # return any plot-transect pairs that should be censused that are not in the data
  missingtransects = dplyr::anti_join(alltransects,plottransect,by=c('plot','transect')) 
  return(data.frame(missingtransects))
}

#' @title check transect start and stop values
#' 
#' @param df data frame of transect data. required column names: plot, transect
#'
check_start_stop = function(df) {
  stopstart = df[which((!(df$start %in% 0:7500)) | (!(df$stop %in% 0:7500)) | df$start > df$stop), ]
  return(stopstart)
}
