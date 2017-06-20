source('Add_months_PortalPlots.r')

library(testthat)
context("checks that plot assignments are being added correctly")
portalplots=update_portal_plots()

test_that("no moondates are skipped or duplicated", {
  
  expect_identical(row(as.matrix(moon_dates$NewMoonNumber))[,1],moon_dates$NewMoonNumber)
  expect_true(all(diff(moon_dates$NewMoonDate) %in% c(29,30)))
})


test_that("no periods skipped or duplicated", {
  
  expect_true(all(diff(moon_dates$Period)==1,na.rm=T))
  expect_true(sum(duplicated(moon_dates$CensusDate,incomparables=NA))==0)
})
