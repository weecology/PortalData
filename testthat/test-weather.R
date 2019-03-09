context("checks new weather data")

weather <- read.csv(file = "../Weather/Portal_weather.csv",header=T,
                   colClasses=c(rep("integer",4), "character", "integer", rep("numeric",19)))
weather$timestamp <- lubridate::ymd_hms(weather$timestamp)
weather_cols <- colnames(weather)

storms <- read.csv(file = "../Weather/Portal_storms.csv",header=T,
                  colClasses=c("character", "integer", rep("numeric",2)))
storms$timestamp <- lubridate::ymd_hms(storms$timestamp)
storms_cols <- colnames(storms)

overlap <- read.csv(file = "../Weather/Portal_weather_overlap.csv",header=T,
                   colClasses=c(rep("integer",4), "character", "integer", rep("numeric",4),
                                "integer", rep("numeric",4)))
overlap$timestamp <- lubridate::ymd_hms(overlap$timestamp)
overlap_cols <- colnames(overlap)

portal4sw <- read.csv(file = "../Weather/Portal4sw_regional_weather.csv",header=T,
                   colClasses=c("character", rep("integer",3), "character", "integer", 
                                rep("character",3), "Date"))
sansimon <- read.csv(file = "../Weather/Sansimon_regional_weather.csv",header=T,
                        colClasses=c("character", rep("integer",3), "character", "integer", 
                                     rep("character",3), "Date"))

test_that("required column names in new weather df", {
  
  expect_identical(weather_cols, 
                   c("year", "month", "day", "hour", "timestamp", "record", "battv", "PTemp_C", 
                     "airtemp", "RH", "precipitation", "BP_mmHg_Avg", "SlrkW", "SlrMJ_Tot", 
                     "ETos", "Rso", "WS_ms_Avg", "WindDir", "WS_ms_S_WVT", "WindDir_D1_WVT", 
                     "WindDir_SD1_WVT", "HI_C_Avg", "SunHrs_Tot", "PotSlrW_Avg", "WC_C_Avg"))
  expect_identical(storms_cols, c("timestamp", "record", "battv", "precipitation"))
  expect_identical(overlap_cols, c("year", "month", "day", "hour", "timestamp", "record",       
                                   "battv", "airtemp", "precipitation", "RH", "record2", 
                                   "battv2", "airtemp2", "precipitation2", "RH2"))
})

test_that("Hour in 100:2400", {
  
  expect_true(all(weather$hour %in% seq(from=100,to=2400,by=100)))
  expect_true(all(overlap$hour %in% seq(from=100,to=2400,by=100)))
})

test_that("Air Temperature ok", {

  expect_true(all(weather$airtemp > -30, na.rm=TRUE))
  expect_true(all(weather$airtemp <= 100, na.rm=TRUE))
  expect_true(all(overlap$airtemp > -30, na.rm=TRUE))
  expect_true(all(overlap$airtemp <= 100, na.rm=TRUE))
})

test_that("Relative humidity ok", {

  expect_true(all(weather$RH > 0, na.rm=TRUE))
  expect_true(all(weather$RH <= 100, na.rm=TRUE))
  expect_true(all(overlap$RH > 0, na.rm=TRUE))
  expect_true(all(overlap$RH <= 100, na.rm=TRUE))
})

test_that("battery status ok", {
  
  expect_true(all(weather$battv > 8.8, na.rm=TRUE))
  expect_true(all(overlap$battv > 8.8, na.rm=TRUE))
  expect_true(all(storms$battv > 9))
})

test_that("Precipitation ok", {
  
  expect_true(all(weather$precipitation >= 0, na.rm=TRUE))
  expect_true(all(weather$precipitation < 100, na.rm=TRUE))
  expect_true(all(overlap$precipitation >= 0, na.rm=TRUE))
  expect_true(all(overlap$precipitation < 100, na.rm=TRUE))
  expect_true(all(storms$precipitation >= 0))
  expect_true(all(storms$precipitation < 12))
})

test_that("Precipitation in multiples of 0.254", {
  
  expect_true(sum(storms$precipitation%%0.254)==0)
})

test_that("no hours missing", {
  
  expect_true(all(diff(weather$timestamp[weather$year>2016])==1))
  expect_true(all(diff(overlap$timestamp)==1))
  
})

test_that("no duplicated rows", {
  
  expect_false(any(duplicated(weather)))
  expect_false(any(duplicated(overlap)))
  expect_false(any(duplicated(storms)))
})
