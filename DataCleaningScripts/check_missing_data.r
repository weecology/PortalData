# This function checks for missing data in new set

#  Input: dataframe, list of fields that should not be empty

check_missing_data = function(df,fields) {
  missing = c()
  for (n in seq(length(df[,1]))) {
    if (any(is.na(df[n,fields])))
    missing = rbind(missing, df[n,])
  }
  print(missing)
}