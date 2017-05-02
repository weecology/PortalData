# Uses a test dataset to make sure rodent data cleaning functions are catching errors

library(XLConnect)
library(testthat)
source('DataCleaningScripts/compare_raw_data.r')
source('DataCleaningScripts/rodent_data_cleaning_functions.R')
source('DataCleaningScripts/check_missing_data.r')
source('DataCleaningScripts/check_all_plots_present.r')

context("checks rodent data cleaning functions")

testfile = 'C:/Users/EC/Desktop/rodent_test_data.xlsx'
wb = loadWorkbook(testfile)
testdat = readWorksheet(wb,sheet=1,header = T,colTypes = XLC$DATA_TYPE.STRING)


test_that("worksheets 1 and 2 match", {

})

test_that("Check that tag numbers match between the sheets and scanner", {
  
})

test_that("Check for conflict between M/F and reproductive characteristics", {
  
})

test_that("Check for duplicate plot/stake pairs", {
  expect_equal(suspect_stake(testdat),data.frame(plot='17',stake='65',stringsAsFactors = F))
})

test_that("check that all 24 plots present in data", {
  expect_equal(all_plots(testdat),c(1,10))
})

test_that("look for missing data ", {
  expect_equal(check_missing_data(testdat,c('mo','dy','yr','period','plot')),c(5,15))
  expect_equal(check_missing_data(testdat[is.na(testdat$note1),],fields=c('stake','species','sex','hfl','wgt')),11)
})
