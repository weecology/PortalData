# Tests to make sure functions in clean_plant_quadrat_data.R are catching errors

library(testthat)
source('../DataCleaningScripts/general_data_cleaning_functions.R')
source('../DataCleaningScripts/plant_data_cleaning_functions.R')

context("checks plant data cleaning functions")

testfile1 = '../DataCleaningScripts/quadrat_test_data.xlsx'
testfile2 = '../DataCleaningScripts/transect_test_data.xlsx'

testdat1 = openxlsx::read.xlsx(testfile1,sheet=1,colNames = T,na.strings = '')
testdat2 = openxlsx::read.xlsx(testfile2,sheet=1,colNames = T,na.strings = '')
splist = read.csv('../Plants/Portal_plant_species.csv',as.is=T)

test_that("worksheets 1 and 2 match", {
  expect_equal(compare_worksheets(testfile1),data.frame(row=10,column='species'))
})

test_that("find species not in existing species list", {
  expect_equal(check_species(testdat1,splist$speciescode),data.frame(testdat1[c(5,21),]))
})

test_that("check for plot/quadrat/species duplicates", {
  expect_equal(duplicate_quads(testdat1),data.frame(testdat1[c(1139,1140),c(5,6,7)]))
})

test_that("check all quadrats present", {
  quads = c(11,13,15,17,31,33,35,37,51,53,55,57,71,73,75,77)
  expect_equal(all_quads(testdat1,plots=seq(24),quads),data.frame(plot=c(6,6,6,14),quadrat=c(13,15,17,73)))
})

test_that("check empty quadrats don't overlap with full quadrats", {
  expect_equal(data.frame(check_empty_quads(testdat1),row.names=c(1,2)),data.frame(testdat1[c(1142,1143),],row.names=c(1,2)))
})

test_that("remove empty quadrats", {
  expect_equal(dim(remove_empty_quads(testdat1))[1],1123)
})

test_that("check for missing data", {
  expect_equal(check_missing_data(testdat1,'abundance'),48)
})

test_that("check all trasects present", {
  expect_equal(all_transects(testdat2,plots=seq(24),transects=c(11,71)),data.frame(plot=7,transect=71))
})

test_that("check transect start/stop values", {
  expect_equal(check_start_stop(testdat2),testdat2[c(233,660,835,1282,1375,1378,1612,1617),])
})
