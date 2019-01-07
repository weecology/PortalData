## Portal Weather Monitoring Data

These data stitch together manually collected weather data (1980 - 1989) and data from three overlapping automated weather stations (1989 - present). This data are continuously updated.

#### Storm Data
In addition to the hourly data, the 2016 station collects precipitation data in 5 minute intervals during storm events. This is in the separate table [Portal_storms](./Weather/Portal_storms.csv).

#### Automated data collection
Below are column descriptions for [Portal_weather](Portal_weather.csv). The data in this file are hourly and span three weather stations. The first only recorded Air Temperature and Precipitation, so other columns are left blank. The column record contains a unique value for each hourly reading on a datalogger. Thus, when the data switches to the new station or a new program, record starts over at 0. The record column can also indicate when missing data from one station were filled in with data from another. Example: during the first several months of the 2016 station going into operation, the battery would drain at night and stop collecting data. Data from the 2002 station were used for these hours.

| Column Name	| Units		| Measurement Type | Value |
| --------------|:-------------:| -----:|:-------------: |
| year		| Years		|	| Year			|	
| month		| Months	|	| Month			|	
| day		| Days		|	| Day			|
| hour		| 2400-hour	|	| Hour			|
| timestamp 	| y-m-d h : m : s	|	|			|
| record 	| 		|	| Record value on weather station 	|
| battv 	| Volts		| Smp	| Battery Voltage       |
| PTemp_C 	| Deg C		| Smp	| Panel Temperature 	|
| airtemp	| Deg C		| Avg	| Air Temperature	|
| RH 		| %		| Smp	| Relative Humidity 	|
| precipitation	| mm		| Tot	| Total Precipitation	|
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

#### Manual data collection

Manually collected data are stored separately in [Portal_weather_9801989](Portal_weather_19801989.csv). **It is necessary to use only summarized monthly rainfall for this data.** 

#### Station overlap
[Portal_weather_overlap](Portal_weather_overlap.csv) contains duplicate values for air temperature and precipitation from the 2002 and 2016 stations. The 2002 station's columns come second and their names end in 2. It can be used to compare the two between stations or create an average. It also contains the `record` column for both stations, so it can be used to determine which station's data are used in the main [Portal_weather](Portal_weather.csv) data.



Please refer to [Methods.md](../SiteandMethods/Methods.md) for a complete description of how these data were collected.
