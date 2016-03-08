# This function compares pit tags entered on data sheets to tags downloaded from scanner

library(XLConnect)


compare_tags = function(ws,scannerfile) {
  
  # extract tag numbers from raw data
  sheets = subset(ws$tag,!is.na(ws$tag))
  
  # load data from scanner
  scandat = read.table(scannerfile, 
                       header=FALSE, 
                       sep='.', 
                       blank.lines.skip=TRUE,
                       col.names=c('v1','tag','date','time'))
  
  # extract 6-digit tag numbers from scanner
  scans = vector()
  for (tag in as.vector(scandat$tag)) {
    scans = append(scans,substr(tag,5,10))
  }
  
  print(paste('in scans not sheets:',setdiff(scans,sheets)))
  print(paste('in sheets not scans:',setdiff(sheets,scans)))

}