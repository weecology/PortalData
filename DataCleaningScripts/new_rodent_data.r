# This script is for cleaning new rodent data.  Data must first be entered in two separate sheets in
# an excel file, by two different people to reduce entry error.



source('compare_raw_data.r')

# ============================================================================
# New file to be checked

filename = 'newdat445'
filepath = 'C:/Users/EC/Dropbox/Portal/PORTAL_primary_data/Rodent/Raw_data/New_data/'

newfile = paste(filepath, filename, '.xlsx', sep='')


# ============================================================================
# Compare double-entered data -- will return 'NULL' if versions match

compare_worksheets(newfile)
