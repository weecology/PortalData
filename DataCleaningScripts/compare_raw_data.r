# This script takes data input from two different users in two sheets of an excel 
# workbook and prints a list of rows that are not identical, for review by the user.
# Output is a data frame of row and column of a mismatch.

# Notes: - row order matters, i.e. data sheets must be entered in same order
#        - worksheets to be compared must be the first two worksheets in the workbook
#        - name of worksheets does not matter
#        - prints "worksheets identical" if two worksheets are identical


library(XLConnect)

# ===============================================================================
# Functions

compare_worksheets = function(excel_file) {
  
  # this function compares the two excel worksheet to identify inconsistencies
  
  # load data from excel workbook
  wb = loadWorkbook(excel_file)
  ws1 = readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)
  ws2 = readWorksheet(wb, sheet = 2, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)
  
  
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


