# These functions are used in the data cleaning process for both rodent data and plant data


#library(openxlsx)


#' @title compare worksheets
#' @description compares sheet 1 and sheet 2 of an excel worksheet of double-entered data (i.e. the two sheets should be identical)
#'              Row order matters: data sheets must be entered in same order in both sheets of the excel file
#'              prints "worksheets identical" if the two worksheets match
#'
#' @param excel_file path to excel file 
#' @return data frame containing row number and column name where any mismatches occur
#' 
compare_worksheets = function(excel_file) {
  
  # this function compares the two excel worksheet to identify inconsistencies
  
  # load data from excel workbook
  ws1 = openxlsx::read.xlsx(excel_file, sheet = 1, colNames = TRUE, na.strings = c('', 'NA', ' '))
  ws2 = openxlsx::read.xlsx(excel_file, sheet = 2, colNames = TRUE, na.strings = c('', 'NA', ''))
  
  
  # if the two worksheets are identical, exit function
  if (identical(ws1,ws2)) {                                   
    print('Worksheets identical')
  } 
  
  # otherwise, loop through rows one at a time
  else {
      unmatched = data.frame(row = c(),column = c())         # empty data frame for storing output
      num_rows = length(ws1$month)
      curr_row = 1
      while (curr_row<=num_rows) {
        v1 = as.character(as.vector(ws1[curr_row,]))          # extract row from worksheet 1
        v2 = as.character(as.vector(ws2[curr_row,]))          # extract row from worksheet 2
        
        # if the two versions of the row are not identical
        if (!identical(v1,v2)) {
          # loop through each element in the row
          col_error = vector()
          for (n in seq(length(v1))) {                        
            if (!identical(v1[n],v2[n])) {
              # add the column name to output vector
              col_error = append(col_error,colnames(ws1)[n])
            }
          }
          # append row and column info to output data frame (curr_row+1 to skip header in excel file)
          unmatched = rbind(unmatched,data.frame(row = curr_row+1,column = col_error))
        }
        curr_row = curr_row+1             # increment index and continue loop
      }
      return(unmatched)
    }
}

#' @title check for presence of all plots in data
#' @description This function checks that all 24 plots are represented in the data (including empty plots)
#' 
#' @param df data frame including a field called 'plot'
#' @return list of missing plots
all_plots = function(df) {
  plots = unique(df$plot)
  missingplots = setdiff(as.character(1:24),plots)
  return(as.numeric(missingplots))
}

#' @title check for missing data
#' @description This function checks for missing data in a dataframe
#' @param df dataframe to be checked
#' @param fields vector of column names that should not be empty
#'  
#' @return vector of rows where data is missing
check_missing_data = function(df,fields) {
  missing = c()
  for (n in seq(length(df[,1]))) {
    if (any(is.na(df[n,fields])))
      missing = rbind(missing, df[n,])
  }
  return(as.numeric(row.names(missing))+1)
}


