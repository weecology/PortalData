# Portal NDVI

The data file (ndvi.csv) is composed of remotely sensed raw values of NDVI for the area around the Portal Project site, centered on the coordinates 31.937769, -109.08029. 

The current data sources include:

* Landsat (a series of satellites)
* GIMMS (an ensemble product from various AVHRR instruments on NOAA satellites)
* MODIS (one instrument aboard the Terra & Aqua satellites)

Further details on the efforts to create an ndvi time series at the site can be found at https://github.com/weecology/NDVIning.

### Other files

An older version of the ndvi time series (NDVI_monthly.csv) is retained for compatibility. It was obtained from the GIMMS NDVI3g dataset, which is a compilation of AVHRR weather sattelite data (Pinzon & Tucker 2014). The original data has a spatial resolution of 8km and a twice monthly temporal resolution, with availability from 1981-2013. It is averaged to monthly NDVI values. 

Pinzon, J., & Tucker, C. (2014). A Non-Stationary 1981–2012 AVHRR NDVI3g Time Series. Remote Sensing, 6(8), 6929–6960. http://doi.org/10.3390/rs6086929
