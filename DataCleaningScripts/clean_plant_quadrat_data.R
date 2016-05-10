# Clean Plant Quadrat Data 
# most of the code taken from EMC
# organized by EKB
# May 10, 2016


library(XLConnect)

source('compare_raw_data.r')

###################
# Load Excel file #
###################


###############################
# Compare double-entered data #
###############################

compare_worksheets("Winter2016.xlsx")
