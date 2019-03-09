context("checks that new moon numbers are being added correctly")

moon_dates <- read.csv("../Rodents/moon_dates.csv",header=T,
                       colClasses=c("integer", "Date", "integer", "Date"))

test_that("no moondates are skipped or duplicated", {
  
  expect_identical(row(as.matrix(moon_dates$newmoonnumber))[,1],moon_dates$newmoonnumber)
  expect_true(all(diff(moon_dates$newmoonnumber)==1))
  expect_true(all(diff(moon_dates$newmoondate) %in% c(29,30)))
  expect_false(any(duplicated(moon_dates$newmoonnumber, incomparables = NA)))
  expect_false(any(duplicated(moon_dates$newmoondate, incomparables = NA)))
})


test_that("no periods skipped or duplicated", {

  expect_true(all(diff(moon_dates$period)==1,na.rm=T))
  expect_false(any(duplicated(moon_dates$period, incomparables = NA)))
  expect_false(any(duplicated(moon_dates$censusdate, incomparables = NA)))
})
