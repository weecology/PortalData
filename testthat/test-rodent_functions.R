# Uses a test dataset to make sure rodent data cleaning functions are catching errors

library(openxlsx)
library(testthat)
source('../DataCleaningScripts/general_data_cleaning_functions.R')
source('../DataCleaningScripts/rodent_data_cleaning_functions.R')


context("checks rodent data cleaning functions")

testfile = '../DataCleaningScripts/rodent_test_data.xlsx'

testdat = read.xlsx(testfile,sheet=1,colNames = T,na.strings = '')
scannerfile = '../DataCleaningScripts/test_tags.txt'


test_that("worksheets 1 and 2 match", {
  expect_equal(compare_worksheets(testfile),data.frame(row=40,column='hfl'))
})

test_that("Check that tag numbers match between the sheets and scanner", {
  expect_equal(compare_tags(testdat,scannerfile),data.frame(where=c('scan','sheet'),tag=c('B267E8','B267EB')))
})

test_that("Check for conflict between M/F and reproductive characteristics", {
  expect_equal(male_female_check(testdat),146)
})

test_that("Check for duplicate plot/stake pairs", {
  expect_equal(suspect_stake(testdat),data.frame(plot=17,stake=65))
})

test_that("check that all 24 plots present in data", {
  expect_equal(all_plots(testdat),c(1,10))
})

test_that("look for missing data ", {
  expect_equal(check_missing_data(testdat,c('month','day','year','period','plot')),c(5,15))
  expect_equal(check_missing_data(testdat[is.na(testdat$note1),],fields=c('stake','species','sex','hfl','wgt')),11)
})

