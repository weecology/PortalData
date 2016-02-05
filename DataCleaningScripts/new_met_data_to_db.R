# This script takes a raw .dat file downloaded directly from the Portal weather 
# station, determines if there are any gaps, and saves the data as a csv on the 
# desktop for easy upload to the database.

# written by Erica Christensen 2/10/14



# ==================================================================================================================
# Functions

create_df = function(rawdata){
  # This function takes an original met file in csv format, cleans it up and puts 
  # it into a dataframe
  
  metdata = subset(rawdata,code==101)                      #extract data points from battery readings (code 102)
  date_info = with(metdata,paste(year, day, hour/100))     #paste year, day, hour into single string
  datetime = strptime(date_info, '%Y %j %H')               #convert into POSIXct date/time format
  dates = as.Date(paste(metdata$year, metdata$day),format = '%Y %j')       #convert into regular r date format
  
  new_df = data.frame(datetime,
                      'Year' = as.integer(format(dates,'%Y')),
                      'Month' = as.integer(format(dates,'%m')),
                      'Day' = as.integer(format(dates,'%d')),
                      'Hour' = as.integer(metdata$hour),
                      'TempAir' = metdata$tempair,
                      'RelHumid' = metdata$relhumid,
                      'TempSoil' = rep(NA,length(datetime)),      # empty vector (of NA) for soil temp
                      "Precipitation (mm)" = metdata$ppt,
                      'Uncert_level' = rep(0,length(datetime)))   # vector of zeros for uncertainty level (assumes raw data is good initially)
  
  names(new_df)[9] = 'Precipitation (mm)'      # make sure this weird column name is correct so it will attach to the database correctly
  
  return(new_df)
}

find_missingdates = function(datetime){
  # This function takes the vector of timestamps from the data (in strptime format) 
  # and finds gaps (assumes data is hourly)
  
  datesthereare = sort(datetime)
  d1 = datesthereare[1]
  d2 = datesthereare[length(datesthereare)-1]
  datesthereshouldbe = as.character(seq(d1,d2,by='hour'))
  missingdates = setdiff(datesthereshouldbe,as.character(datesthereare))
  
  return(missingdates)
}

# ======================================================================================================
# Main code

# Open raw .dat file of new data
metfolder = "C:\\Users\\EC\\Dropbox\\Portal\\PORTAL_primary_data\\Weather\\Raw_data\\2002_Station\\"

metfile = "Met445"

rawdata = read.csv(paste(metfolder,metfile,'.dat',sep=''),head=F,sep=',',col.names=c('code','year','day','hour','ppt','tempair','relhumid'))

new_df = create_df(rawdata)
missingdates = find_missingdates(new_df$datetime)

#removes "datetime" column from dataframe (not present in database version)
final_df = subset(new_df,select=-datetime)


# =======================================================================================================
# some basic error checks

# air temp
if (any(new_df$TempAir > 100)) {temperr = 'Yes'} else {temperr = 'No'}
# rel humidity
if (any(new_df$RelHumid >100)) {humerr = 'Yes'} else if (any(new_df$RelHumid < 0)) {humerr = 'Yes'} else {humerr = 'No'}
# battery reading (should be ~12.5)
if (any(rawdata[rawdata$code==102,5] < 11)) {batterr = 'Yes'} else {batterr = 'No'}

print(paste('TempAir error:',temperr))
print(paste('RelHumid error:',humerr))
print(paste('Battery error:',batterr))
print(paste('there are ',length(missingdates),' missing entries'))
print(paste('first entry is',new_df$datetime[1]))


# ===================================================================================================
# Save processed data file

outfolder = 'C:\\Users\\EC\\Desktop\\'
outfile = paste(outfolder,metfile,'.csv',sep='')
write.csv(final_df,file=outfile,row.names=F,na='')
