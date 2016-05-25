# This function looks for duplicate stake numbers within a plot (rodent data) that should be labeled as suspect stake

suspect_stake = function(df) {
  
  plotstake = paste(df$plot,df$stake)
  dups = plotstake[duplicated(plotstake)]
  print(c('suspect plot/stake: ',dups))
  
}
