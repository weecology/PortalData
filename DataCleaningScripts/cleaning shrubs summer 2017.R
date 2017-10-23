# RMD October 19, 2017


# Load raw double-entered Excel files from Dropbox
# Compare worksheets
# Manually fix single-cell errors. Fix missing/extra rows by editing the Excel file.
# Once worksheets match, save table as a .csv on Dropbox
# Continue cleaning that .csv using clean_shrub_transect_data.R

library(openxlsx)
library(dplyr)

season <-  'Summer'
year <-  '2017'
filepath <-  '/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/'

excel_file <-  paste(filepath, "ShrubTransect_", season, year, '.xlsx', sep='')

# load data from excel workbook
ws1 = read.xlsx(excel_file, sheet = 1, colNames = TRUE, na.strings = c('', 'NA', ' '))
ws2 = read.xlsx(excel_file, sheet = 2, colNames = TRUE, na.strings = c('', 'NA', ''))

# if the two worksheets are identical, exit function
if (identical(ws1,ws2)) {                                   
  print('Worksheets identical')
} else {
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
  
}
  
  i = 1
  
  i  = i + 1
  unmatched[i, ]
  ws1[unmatched[i, 'row'] -1 , ]
  ws2[unmatched[i, 'row'] - 1, ]
  

  ws2[1665, 'start'] <- 6790
  ws2[1653, 'start'] <- 4970
  ws2[1571, 'start'] <- 880
  ws1[1548, 'start'] <- 4438
  ws2[1541, 'species'] <- 'mimo acul'
  ws1[1507, 'start'] <- 3945
  ws2[1506, 'height'] <- 32
  ws2[1474, 'species'] <- 'mimo acul'
  ws1[1470, 'start'] <- 5224
  ws1[1416, 'start'] <- 2352
  ws2[1375, 'stop'] <- 4105
  ws2[1289, 'stop'] <- 2105
  ws2[1282, 'stop'] <- 1554
  ws1[1269, 'start'] <- 6695
  ws2[1235, 'stop'] <- 1685
  ws2[1235, 'start'] <- 1670
  ws2[1234, 'stop'] <- 1695
  ws2[1234, 'start'] <- 1690
  ws2[1225, 'start'] <- 6874
  ws1[1222, 'stop'] <- 6251
  ws1[1222, 'start'] <- 6225
  ws1[1210, 'height'] <- 100
  ws1[1187, 'stop'] <- 1876
  ws2[1122, 'start'] <- 3862
  ws2[1105, 'start'] <- 664
  ws1[1077, 'stop'] <- 526
  ws1[1050, 'stop'] <- 7139
  ws2[1049, 'start'] <- 6882
  ws1[1043, 'start'] <- 4798
  ws2[1040, 'height'] <- 190
  ws2[1036, 'start'] <- 2666
  ws2[998, 'start'] <- 2371
  ws2[660, 'stop'] <- 2185
  ws1[660, 'stop'] <- 2185
  ws1[951, 'height'] <- 31
  ws2[887, 'species'] <- 'lyci ande'
  ws2[886, 'species'] <- 'lyci ande'
  ws2[871, 'height'] <- 45
  ws2[868, 'species'] <- 'guti saro'
  ws2[860, 'species'] <- 'mimo acul'
  ws2[857, 'species'] <- 'mimo acul'
  ws2[844, 'stop'] <- 5287
  ws2[841, 'start'] <- 4260
  ws2[836, 'start'] <- 2696
  ws2[835, 'stop'] <- 2675
  ws2[808, 'start'] <- 2960
  ws2[786, 'height'] <- 30
  ws2[766, 'height'] <- 40
  ws2[760, 'species'] <- 'mimo acul'
  ws2[699, 'height'] <- 109
  ws2[699, 'stop'] <- 2530
  ws1[653, 'height'] <- 250
  ws1[645, 'start'] <- 6399
  ws1[604, 'stop'] <- 5805 
  ws2[591, 'start'] <- 3882
  ws2[587, 'start'] <- 2830
  ws1[488, 'start'] <- 2860
  ws2[486, 'height'] <- 151
  ws2[484, 'stop'] <- 2552
  ws1[196, 'stop'] <- 4124
  ws2[203, 'start'] <- 4849
  ws2[206, 'stop'] <- 5282
  ws2[213, 'stop'] <- 6278
  ws2[283, 'start'] <- 1994
  ws1[291, 'height'] <- 56
  ws2[301, 'stop'] <- 4959
  ws2[397, 'start'] <- 6838
  ws1[471, 'height'] <- 138
  
  
write.csv(ws1, '/Users/renatadiaz/Dropbox/Portal/PORTAL_primary_data/Plant/TRANSECTS/ShrubTransects(2015-present)/RawData/ShrubTransect_Summer2017_clean.csv', row.names = FALSE)

  