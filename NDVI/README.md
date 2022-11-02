# Portal NDVI

The data file (ndvi.csv) is composed of remotely sensed raw values of NDVI for an area 1000 m in radius around the Portal Project site, centered on the coordinates 31.937769, -109.08029. 

<img src="figures/portal_area.png" width="400px">

The current data sources are Landsat 8 and 9. e.g. The Portal area is covered by 2 tiles from the Landsat8 paths:

<img src="figures/tiles.png" width="400px">

The current source is the USGS/EROS api. NDVI is calculated as (B5 - B4)/(B5 + B4). Thus, the USGS source indicates a distinct time series from the AWS source, in which sr_ndvi was provided pre-calculated.

Other sources in the dataset include:

* Landsat (sensors 5-9, from a variety of sources)
* GIMMS (an ensemble product from various AVHRR instruments on NOAA satellites)
* MODIS (one instrument aboard the Terra & Aqua satellites)

Further details on the efforts to create an ndvi time series at the site can be found at https://github.com/weecology/NDVIning.

### Other files

An older version of the ndvi time series (NDVI_monthly.csv) is retained for compatibility. It was obtained from the GIMMS NDVI3g dataset, which is a compilation of AVHRR weather sattelite data (Pinzon & Tucker 2014). The original data has a spatial resolution of 8km and a twice monthly temporal resolution, with availability from 1981-2013. It is averaged to monthly NDVI values. 

Pinzon, J., & Tucker, C. (2014). A Non-Stationary 1981–2012 AVHRR NDVI3g Time Series. Remote Sensing, 6(8), 6929–6960. http://doi.org/10.3390/rs6086929
