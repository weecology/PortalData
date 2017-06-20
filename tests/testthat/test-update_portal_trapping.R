source('Create_portal_rodent_trapping_records.r')

library(testthat)
context("checks new trapping dates are being added correctly")

trapping=update_portal_rodent_trapping()

test_that("no skipped periods, in order", {
  
  expect_true(all(diff(unique(trapping$Period))==1))
})


test_that("no duplicate data", {

  expect_true(sum(duplicated(trapping))==0)
})
