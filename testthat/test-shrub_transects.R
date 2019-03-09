context("checks shrub transect data")

data <- read.csv("../Plants/Portal_plant_transects_2015_present.csv")
old_transects <- read.csv("../Plants/Portal_plant_transects_1989_2009.csv")
species <-  read.csv('../Plants/Portal_plant_species.csv')

test_that("valid year", {
  
  expect_true(all(data$year %in% 1981:max(data$year)))
})

test_that("valid plot", {
  
  expect_true(all(data$plot %in% 1:24))
})

test_that("valid transect", {
  
  expect_true(all(data$transect %in% c(11,71)))
})

test_that("valid species", {
  
  expect_true(all(data$species %in% species$speciescode))
})

test_that("valid start", {
  
  expect_true(all(data$start %in% 0:7500))
})


test_that("valid stop", {
  
  expect_true(all(data$stop %in% 0:7500))
})


test_that("stop greater than start", {
  
  expect_true(all(data$stop >= data$start))
})

test_that("valid height", {
  
  expect_true(min(data$height, na.rm = T) > 0)
  expect_true(max(data$height, na.rm = T) <= 400)
})

test_that("no duplicate data", {
  
  expect_true(sum(duplicated(data))==0)
})

test_that("valid year", {
  
  expect_true(all(old_transects$year %in% c(1989,1992,1995,1998,2001,2004,2009)))
})

test_that("valid plot", {
  
  expect_true(all(old_transects$plot %in% 1:24))
})

test_that("valid transect", {
  
  expect_true(all(old_transects$transect %in% c("NW","SW","NE","SE","")))
})

test_that("valid species", {
  
  expect_true(all(old_transects$species %in% species$speciescode))
})

test_that("valid point", {
  
  expect_true(all(old_transects$point %in% c(1:250,NA)))
})


