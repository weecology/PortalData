# Problems:
#  



# This script takes data input from two different users in two sheets of an excel 
# workbook and prints a list of rows that are not identical, for review by the user.

# Note: name of excel file should be changed in line 17 of this script



rm(list=ls(all=TRUE))

library(XLConnect)

filename = 'newdat445'
filepath = 'C:/Users/ellen.bledsoe/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/'

# ===============================================================================
# functions

compare_by_row = function(ws1,ws2) {
  # this function compares the two excel worksheets row by row to identify inconsistencies
  num_rows = length(ws1$mo)
  unmatched = vector()
  curr_row = 1
  while (curr_row<=num_rows) {
    row1 = as.character(as.vector(ws1[curr_row,]))              #extract single row
    row1[is.na(row1)] = ''                                      #remove NAs
    row2 = as.character(as.vector(ws2[curr_row,]))
    row2[is.na(row2)] = ''
    if (!all(row1==row2)) {
      unmatched = append(unmatched,curr_row+1)
    }
    curr_row = curr_row+1
  }
  return(unmatched)
}

# ================================================================================
# data files

newfile = paste(filepath, filename, '.xlsx', sep='')

# ===============================================================================
# compare two copies of input data

wb = loadWorkbook(newfile)
ws1 = readWorksheet(wb, sheet = 1, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)
ws2 = readWorksheet(wb, sheet = 2, header = TRUE,colTypes = XLC$DATA_TYPE.STRING)

unmatched = compare_by_row(ws1,ws2)
print(c('unmatched rows:',unmatched))

