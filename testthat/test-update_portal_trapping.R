context("checks new trapping dates are being added correctly")

trappingdat <- read.csv("../Rodents/Portal_rodent_trapping.csv") 
rodentdat <- read.csv("../Rodents/Portal_rodent.csv")
newperiod <- max(rodentdat$period)
newdat <- rodentdat[rodentdat$period==newperiod,]
newtrapping <- trappingdat[trappingdat$period==newperiod,]

test_that("new period in data", {
  
  expect_true(max(trappingdat$period) == newperiod)
})

test_that("no skipped periods, in order", {
  
  expect_true(all(diff(unique(trappingdat$period))==1))
})


test_that("no duplicate data", {

  expect_false(any(duplicated(trappingdat)))
})

test_that("all plots added",{
  expect_true(length(newtrapping$plot)==24)
})

test_that("effort added correctly", {
  if(14 %in% newdat$note1) { 
  expect_false(all(newtrapping$effort %in% c(0,49)))
  }
  else {
    expect_true(all(newtrapping$effort %in% c(0,49)))
  }
})
