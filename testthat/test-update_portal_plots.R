source('../DataCleaningScripts/update_portal_plots.R')

library(testthat)
context("checks that plot assignments are being added correctly")
portal_plots=update_portal_plots()

test_that("valid data", {
  expect_true(all(portal_plots$month %in% 1:12))
  expect_true(all(portal_plots$plot %in% 1:24))
  expect_true(all(portal_plots$treatment %in% c("control","removal","exclosure","spectabs")))
})


test_that("no duplicate data", {

  expect_true(sum(duplicated(portal_plots))==0)
})

