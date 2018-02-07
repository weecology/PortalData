source('../DataCleaningScripts/update_portal_rodent_trapping.r')

library(testthat)
context("checks new trapping dates are being added correctly")

trappingdat=update_portal_rodent_trapping()

test_that("no skipped periods, in order", {
  
  expect_true(all(diff(unique(trappingdat$period))==1))
})


test_that("no duplicate data", {

  expect_true(sum(duplicated(trappingdat))==0)
})
