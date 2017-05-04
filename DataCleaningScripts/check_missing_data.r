#' This function checks for missing data in a dataframe

#'  @param df dataframe to be checked
#'  @param fields vector of column names that should not be empty
#'  
#'  @return vector of rows where data is missing

check_missing_data = function(df,fields) {
  missing = c()
  for (n in seq(length(df[,1]))) {
    if (any(is.na(df[n,fields])))
    missing = rbind(missing, df[n,])
  }
  return(as.numeric(row.names(missing))+1)
}
