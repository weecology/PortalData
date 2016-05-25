# This function checks that all plots are represented in the data (including empty plots)

#    Input: data frame including a field called 'plot'



all_plots = function(df) {
  plots = unique(df$plot)
  missingplots = setdiff(as.character(1:24),plots)
  print(paste('missing plots:',missingplots))
}
