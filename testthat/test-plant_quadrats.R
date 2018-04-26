library(testthat)
context("checks new plant quadrat data and plant species list")

data <- read.csv("../Plants/Portal_plant_quadrats.csv")
species <-  read.csv('../Plants/Portal_plant_species.csv')

test_that("valid year", {
  
  expect_true(all(data$year %in% 1981:max(data$year)))
})

test_that("valid season", {
  
  expect_true(all(data$season %in% c("winter","summer")))
})

test_that("valid plot", {
  
  expect_true(all(data$plot %in% 1:24))
})

test_that("valid quadrat", {
  
  expect_true(all(data$quadrat %in% c(11,13,15,17,31,33,35,37,51,53,55,57,71,73,75,77)))
})

test_that("valid species", {
  
  expect_true(all(data$species %in% species$speciescode))
})

test_that("valid abundance", {
  
  expect_true(all(na.omit(data$abundance) %in% 0:2400))
})

test_that("valid cover", {
  
  expect_true(all(data$cover[which(data$cover!=0.1)] %in% 1:100))
})


test_that("no duplicate data", {
  
  expect_true(sum(duplicated(data))==0)
})


test_that("valid duration in Portal_plant_species", {
  
  expect_true(all(species$duration %in% c('Perennial','Annual','Unknown')))
})

test_that("valid community in Portal_plant_species", {
  
  expect_true(all(species$community %in% c('Shrub','Summer Annual','Perennial Forb','Summer and Winter Annual','Unknown','Winter Annual','Subshrub','Perennial Grass')))
})
