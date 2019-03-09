context("checks that plot assignments are being added correctly")

portal_plots <- read.csv("../SiteandMethods/Portal_plots.csv")

test_that("valid data", {
  expect_true(all(portal_plots$month %in% 1:12))
  expect_true(all(portal_plots$plot %in% 1:24))
  expect_true(all(portal_plots$treatment %in% c("control","removal","exclosure","spectabs")))
})


test_that("no duplicate data", {

  expect_false(any(duplicated(portal_plots)))
})

