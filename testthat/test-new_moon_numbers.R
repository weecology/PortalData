source('../DataCleaningScripts/new_moon_numbers.r')

library(testthat)
context("checks that new moon numbers are being added correctly")
moon_dates=update_moon_dates()

test_that("no moondates are skipped or duplicated", {
  
  expect_identical(row(as.matrix(moon_dates$newmoonnumber))[,1],moon_dates$newmoonnumber)
  expect_true(all(diff(moon_dates$newmoondate) %in% c(29,30)))
})


test_that("no periods skipped or duplicated", {

  expect_true(all(diff(moon_dates$period)==1,na.rm=T))
  expect_true(sum(duplicated(moon_dates$censusdate,incomparables=NA))==0)
})
