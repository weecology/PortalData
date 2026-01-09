# Portal NDVI

The data file (ndvi.csv) is composed of remotely sensed raw values of NDVI for an area 1000 m in radius around the Portal Project site, centered on the coordinates 31.937769, -109.08029. 

<img src="figures/portal_area.png" width="400px">

The current data source is Landsat 9 and the Portal area is covered by 2 tiles from the Landsat path (Landsat 8 tiles also shown for comparison):

<img src="figures/tiles.png" width="400px">

The current source is the USGS/EROS API. NDVI is calculated as (B5 - B4)/(B5 + B4). Thus, the USGS source indicates a distinct time series from the AWS source, in which sr_ndvi was provided pre-calculated.

Other sources in the dataset include:

* Landsat (sensors 5-9, from a variety of sources)
* GIMMS (an ensemble product from various AVHRR instruments on NOAA satellites)
* MODIS (one instrument aboard the Terra & Aqua satellites)

Due to the length of the the time-series we focus on the use of landsat data for analysis and a combined time-series across Landsats 5-9 is what is provided by default by the [`ndvi()`](https://weecology.github.io/portalr/reference/ndvi.html) function in our [portalr](https://weecology.github.io/portalr/) R package.

## Correcting for differences between sensors

The sensors on the different Landsat missions differ and this can produce shifts in the resulting NDVI values across the time-series.
Each Landsat mission overlaps with the previous mission for the purpose of comparison (see [portal-ndvi-shift.R](portal-ndvi-shift.R)).
We have compared each mission to the previous mission using data from the two sensors that is collected withing one of each other to evaluate these differences.

<img src="figures/ndvi-sensor-comparison-one-to-one.png" width="400px">

<img src="figures/ndvi-sensor-comparison-histograms.png" width="400px">

Since notable shifts are present and they seem to be consistent across NDVI values we recommend correcting the means to a common mean based on Landsat 5.
Calulated corrections to the previous sensor for Landsats 7-9 are:

```
# A tibble: 3 × 2
  sensor2  correction_to_prev_sensor
  <chr>                        <dbl>
1 Landsat7                   0.00179
2 Landsat8                  -0.0361
3 Landsat9                  -0.00249
```

So to calculate a value for Landsat 9 one would first correct it to Landsat 8 and then to Landsat 7 and then to Landsat 5:

> Landsat9_corrected = Landsat9_raw - 0.00249 - 0.361 + 0.00179

Additional details of the history of satelittes and sensors along with earlier efforts to create a continuous NDVI time series for the site can be found at https://github.com/weecology/NDVIning.

## Other files

An older version of the ndvi time series (NDVI_monthly.csv) is retained for compatibility. It was obtained from the GIMMS NDVI3g dataset, which is a compilation of AVHRR weather sattelite data (Pinzon & Tucker 2014). The original data has a spatial resolution of 8km and a twice monthly temporal resolution, with availability from 1981-2013. It is averaged to monthly NDVI values. 

Pinzon, J., & Tucker, C. (2014). A Non-Stationary 1981–2012 AVHRR NDVI3g Time Series. Remote Sensing, 6(8), 6929–6960. http://doi.org/10.3390/rs6086929
