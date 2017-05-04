#' This function checks that all 24 plots are represented in the data (including empty plots)
#' 
#' 
#' 
#'
#' @param df data frame including a field called 'plot'



all_plots = function(df) {
  plots = unique(df$plot)
  missingplots = setdiff(as.character(1:24),plots)
  return(as.numeric(missingplots))
}
