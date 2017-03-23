# Portal Weather Monitoring Metadata

[**Long-term monitoring of weather near Portal, Arizona (1980 – 2013).**](http://onlinelibrary.wiley.com/doi/10.1890/15-2115.1/full)


### Abstract

The data set includes continuous weather monitoring near Portal, Arizona. From 1980-1989, daily minimum and maximum air temperature values were recorded at the site. Manually collected precipitation data is also available. Unlike the temperature data, the precipitation data for these years is not daily and should only be used after summarizing over months or years. In 1989, the site switched to an automated weather station which recorded hourly rainfall amounts and air temperatures. In 2002, this weather station was updated and continues to collect hourly precipitation and air temperature. This data will be updated.

### Site description: 

The 24 experimental plots cover an area not more than 20 ha in size. Due to the small spatial-scale of the plot and the spatial scale of the typical precipitation event, there is only one weather station for the site. This station has been located in the same general vicinity of the 20 ha site since 1980 (see [Portal Overview Metadata, Figure 1](./SiteandMethods/Portal_Figure1.tif) for location).

### Data Collection: 

Before 1989, precipitation was collected in a standard “manual” rain gauge and approximately weekly a volunteer residing in the vicinity would visit the site and collect data on rainfall amounts. The Day column in the pre-1989 data therefore does not reflect actual daily rainfall, but provides a record of data collection only. **It is necessary to use only summarized monthly rainfall for this data.** The temperature data was recorded by a circular hygrothermograph and daily minimum and maximum temperatures were transcribed onto datasheets (see picture in metadata). In 1989, an automated weather station was installed at the site (Campbell Scientific) capable of recording precipitation amounts and air temperature on an hourly basis. The automated and manual collection protocols were run concurrently for approximately 2 months until the old weather station was hit by lightning. No information currently exists on the make or model of the rain gauge for the first automated weather station. After a serious malfunction in February 2002, a new automated weather station (Campbell Scientific) was installed in December 2002. The rain gauge associated with the current weather station is a Texas Electronics 8 inch gauge (TE525WS-L). The datalogger records hourly precipitation and air temperature. Note that this is finer scale weather information than was recorded previously at the site. The inclusion of the temperature data also constitutes more weather information than was made available in the previous data publication (Ernest et al 2009). The weather data are divided into three files (1980-1989, 1989-2017 and 2016 - present) to reflect the different frequencies of data collection and overlaps between stations. In 2011, gaps exist in the weather data.

*1980-1989*: Very little documentation exists regarding collection of weather data prior to 1989. Though we know from the charts that a circular hygrothermograph was used to collect temperature data, we do not know the instrumentation used. Humidity was also recorded, but we know from notes on the charts that it was considered unreliable. Our only record of the collection of precipitation data is the date on which a non-zero amount was recorded. We have included precipitation in the daily data table to retain this collection record. Of course, this does not reflect actual daily rainfall. The daily precipitation data should absolutely not be used, but should be summed over longer time periods to correct for the irregular collection. 

*1989-2017*: Data were downloaded monthly in conjunction with the monthly rodent census. While we do not appear to have documentation on the accuracy of the rain gauge associated with the first automated weather station, we do know that it was a tipping bucket rain gauge and the data suggest that each tip was equal to 0.254 mm. This is equivalent to the tipping bucket rain gauge associated with the weather station that began operation in 2002. Note: weather station battery was bad from Oct 2015 to Feb 2016, use data from this period with caution

*2016-present*: This station was installed in November of 2016. In addition to a temperature sensor and rain gauge, it has a relative humidity sensor, pyranometer, wind monitor and barometer. Data is uploaded remotely each day. Data is organized as described below. In addition to the hourly data, this station collects precipitation data in 5 minute intervals during storm events. This is in the separate table [Storms](./Weather/Portal_storms.csv).

| Column Name	| Units		| Measurement Type | Value |
| --------------|:-------------:| -----:|:-------------: |
| Year		| Years		|	| Year			|	
| Month		| Months	|	| Month			|	
| Day		| Days		|	| Day			|
| Hour		| 2400-hour	|	| Hour			|
| TIMESTAMP 	| y-m-d h : m : s	|	|			|
| RECORD 	| 		|	| Unique Record Value 	|
| BattV 	| Volts		| Smp	| Battery Voltage       |
| PTemp_C 	| Deg C		| Smp	| Panel Temperature 	|
| AirTC_Avg 	| Deg C		| Avg	| Air Temperature	|
| RH 		| %		| Smp	| Relative Humidity 	|
| Rain_mm_Tot	| mm		| Tot	| Total Precipitation	|
| BP_mmHg_Avg	| mmHg		| Avg	| Barometric Pressure	|
| SlrkW_Avg	| kW/m^2	| Avg	| Average Radiation	|
| SlrMJ_Tot	| MJ/m^2	| Tot	| Total Radiation 	|
| ETos		| Deg C		| ETXs	| Total Evapotranspiration |
| Rso		| Deg C		| Rso	| Clear Sky Solar Radiation |
| WS_ms_Avg	| meters/second	| Avg	| Wind Speed		|
| WindDir	| degrees	| Smp	| Wind Direction	|
| WS_ms_S_WVT	| meters/second	| WVc	| Wind Vector: Speed	|
| WindDir_D1_WVT | Deg		| WVc	| Wind Vector: Direction |
| WindDir_SD1_WVT | Deg		| WVc	| Wind Vector: Std Dev (Dir) 	|
| HI_C_Avg	| Deg C		| Avg	| Heat Index		|
| SunHrs_Tot	| hours		| Tot	| Sunshine Hours 	|
| PotSlrW_Avg	| W/m^2		| Avg	| Potential Solar Radiation |
| WC_C_Avg	| Deg C		| Avg	| Wind Chill		|



