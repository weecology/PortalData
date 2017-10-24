library(testthat)
context("checks new shrub transect data")

data <- read.csv("../Plants/Portal_plant_transects_2015_present.csv")
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
  
  expect_true(all(data$height %in% 0:400))
})

test_that("no duplicate data", {
  
  expect_true(sum(duplicated(data))==0)
})

