#Guide to Portal Data Cleaning Procedures

A description of the cleaning procedures applied to new Portal data before they are appended to the reevant data table. Numbered descriptions refer to functions in this folder, applied, in order, to the new data.

##Rodent Data
1. Compare double-entered data
2. Quality control
		*check for all plots present
		*check for appropriate dates
		*compare tag data to reader tag numbers
		*check body size measurements against Species
		*check reproductive status against sex
		*flag missing data
		*flag duplicate stakes
		*add R to all removed rodents
3. Correct recaptures
		*add 'new tag' * to all new captures
		*check for consistent species and sex on recaptures
4. Append new data to table, write table to file

##Plant Data
1. Compare double-entered data
2. Quality Control
		*check for all plots present
		*check for all quadrats present
		*check for duplicate species on quadrat
		*flag missing values
3.Remove empty quadrats, append data to table, write table to file

##Weather Data
1. Quality Control
		*dates align with previous data
		*check data range on temperature, relhumid, precip
		*check battery voltage
2. Append new data, write table to file

	