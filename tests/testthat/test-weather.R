source("new_weather_data.R")
library(testthat)
context("checks new weather data")

data=new_met_data()
newdata = data[[1]]
newdata_cols = colnames(newdata)
weather = data[[2]]
weather_cols = colnames(weather)
stormsnew = data[[3]]
stormsnew_cols = colnames(stormsnew)
storms = data[[4]]
storms_cols = colnames(storms)

test_that("required column names in new weather df", {
  
  expect_identical(weather_cols, newdata_cols)
  expect_identical(storms_cols, stormsnew_cols)
})

test_that("Hour in 100:2400", {
  
  expect_true(sum(newdata$Hour %in% seq(from=100,to=2400,by=100))==dim(newdata)[1])
})

test_that("Air Temperature ok", {

  expect_true(sum(newdata$TempAir < -30)==0)
  expect_true(sum(newdata$TempAir > 100)==0)
})

test_that("Relative humidity ok", {

  expect_true(sum(newdata$RH < 0)==0)
  expect_true(sum(newdata$RH > 100)==0)
})

test_that("battery status ok", {
  
  expect_true(sum(newdata$BattV < 9)==0)
  expect_true(sum(stormsnew$BattV < 9) ==0)
})

test_that("Precipitation ok", {
  
  expect_true(sum(newdata$Precipitation < 0)==0)
  expect_true(sum(newdata$Precipitation > 100)==0)
  expect_true(sum(stormsnew$Rain_mm_Tot < 0) ==0)
  expect_true(sum(stormsnew$Rain_mm_Tot > 10) ==0)
})

test_that("Precipitation in multiples of 0.254", {
  
  expect_true(sum(newdata$Precipitation%%0.254)==0)
  expect_true(sum(stormsnew$Rain_mm_Tot%%0.254)==0)
})


test_that("start of new data lines up with end of existing data", {
  
  expect_identical(tail(weather$TIMESTAMP,n=1)+3600,newdata$TIMESTAMP[1])
})

test_that("no hours missing", {
  
  expect_true(sum(diff(newdata$TIMESTAMP)!=1)==0)
})

test_that("no identical rows in newdata and weather", {
  
  expect_true(sum(duplicated(dplyr::bind_rows(weather,newdata)))==0)
})

test_that("no identical rows in new storm data and storms", {
  
  expect_true(sum(duplicated(dplyr::bind_rows(storms,stormsnew)))==0)
})



