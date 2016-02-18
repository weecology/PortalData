# This script is for cleaning new rodent data.  Data must first be entered in two separate sheets in
# an excel file, by two different people to reduce entry error.



source('compare_raw_data.r')
source('compare_tags.r')

# ============================================================================
# New file to be checked

newperiod = '445'
filepath = 'C:/Users/EC/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/'

newfile = paste(filepath, 'newdat', newperiod, '.xlsx', sep='')
scannerfile = paste(filepath, 'tag scans/tags', newperiod, '.txt', sep='')

# ============================================================================
# Compare double-entered data -- will return 'Worksheets identical' if versions match

compare_worksheets(newfile)

# ============================================================================
# General error checking

# Compare tag numbers entered on sheets to scanner download
compare_tags(newfile,scannerfile)
