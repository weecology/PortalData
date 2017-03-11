#Portal Plant Monitoring Metadata

[**Long-term monitoring and experimental manipulation of a Chihuahuan Desert plant community near Portal, Arizona (1981 – 2013).**](http://onlinelibrary.wiley.com/doi/10.1890/15-2115.1/full)

###Abstract

The data set includes ongoing remotely sensed NDVI values of an arid ecosystem in near Portal, Arizona.

###Site description: 

Within the 20 ha study area there are 24 experimental plots. Each plot has an area of 0.25 ha and is fenced to regulate rodent access to the plot. Rodent treatments include controls, kangaroo rat removal, and rodent removal. The ant community, which is also predominately granivorous, is also manipulated. Ant treatments include controls and ant removals. 
On each plot there are 16 permanent plant stations marked by rebar stakes forming a 4x4 grid. 

####Description of composite NDVI:

The Composite NDVI file (monthly_NDVI.csv) is a combination of the LANDSAT and MODIS NDVI values for the area around the Portal Project site. 
Combining these data occurred in two stages.
1)	Combining LANDSATs. The LandSat data was obtained from different satellites over the years. One of those satellites had known issues. The code in LANDSAT.R compares the data from the different satellites when they overlapped and calculated a regression to correct data from one satellite to be more comparable with the other satellites. This code then generates a single LANDSAT NDVI timeseries.
2)	Calculating Monthly NDVI from LandSat. LandSat data is individual images – sometimes multiple ones with in a month. To create a monthly time series, these values were combined using LS_time.R
3)	Combining MODIS and LandSat. A similar process was conducted with MODIS and LandSat to make sure that the NDVI values obtained from the different satellites were comparable. MODIS was then corrected using the regression to be more comparable with LandSat and the timeseries were combined using MODIS_LANDSAT.R. 
