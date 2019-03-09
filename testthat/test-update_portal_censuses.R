context("checks new plant census dates are being added correctly")

censuses <- read.csv("../Plants/Portal_plant_censuses.csv")
census_dates <- read.csv("../Plants/Portal_plant_census_dates.csv")
quadrats <- read.csv("../Plants/Portal_plant_quadrats.csv")

test_that("valid season", {
  
  expect_true(all(censuses$season %in% c("winter","summer")))
})

test_that("valid year", {
  
  expect_true(all(censuses$year %in% 1981:max(censuses$year,na.rm=T)))
})

test_that("valid plot", {
  
  expect_true(all(censuses$plot %in% 1:24))
})

test_that("valid quadrat", {
  
  expect_true(all(censuses$quadrat %in% c(11,13,15,17,31,33,35,37,51,53,55,57,71,73,75,77)))
})

test_that("valid censuses", {
  
  expect_true(all(censuses$censused %in% c(0,1)))
})

test_that("valid area", {
  
  expect_true(all(censuses$area %in% c(0,0.25)))
})

test_that("no duplicate data", {
  
  expect_false(any(duplicated(censuses)))
})

test_that("census dates updated", {
  
  expect_true(unique(paste(quadrats$year, quadrats$season) %in%
                     paste(census_dates$year, census_dates$season)))
})



