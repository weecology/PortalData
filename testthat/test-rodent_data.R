library(testthat)
library(dplyr)
context("checks that rodent data values are valid")

data = read.csv("../Rodents/Portal_rodent.csv",
  na.strings = c(""), colClasses = c('tag' = 'character'),
  stringsAsFactors = FALSE)

stakes = c(11:17,21:27,31:37,41:47,51:57,61:67,71:77)
stakedata=data %>% filter(period > 0, complete.cases(stake))

species = read.csv("../Rodents/Portal_rodent_species.csv",na.strings = c(""), 
          colClasses=c(speciescode="character"))

bodysizedata = data %>% filter(!(note1 == 12),!is.na(species)) %>% group_by(species) %>% 
  left_join(species,by=c("species"="speciescode")) %>% filter(censustarget==1)
  

test_that("year, month and day are valid", {
  
  expect_true(all(data$year %in% 1977:format(Sys.Date(),"%Y")))
  expect_true(all(data$month %in% 1:12))
  expect_true(all(data$day %in% 1:31))
  
})

test_that("plot values are valid", {
  
  expect_true(all(na.omit(data$plot) %in% 1:24))
  
})

test_that("stake values are valid", {
  
  expect_true(all(stakedata$stake %in% stakes))
  
})

test_that("species codes are valid", {
  
  expect_true(all(na.omit(data$species) %in% species$speciescode))
  
})

test_that("sex codes are valid", {
  
  expect_true(all(na.omit(data$sex) %in% c("M","F")))
  
})

test_that("reproduction codes are valid", {
  
  expect_true(all(na.omit(data$reprod) == "Z"))
  expect_true(all(na.omit(data$age) == "J"))
  expect_true(all(na.omit(data$testes) %in% c("S","R","M")))
  expect_true(all(na.omit(data$vagina) %in% c("S","P","B")))
  expect_true(all(na.omit(data$pregnant) == "P"))
  expect_true(all(na.omit(data$nipples) %in% c("R","E","B")))
  expect_true(all(na.omit(data$lactation) == "L"))
  
})

test_that("body size measurements are reasonable for species", {
  
  expect_true(all(bodysizedata$hfl >= bodysizedata$minhfl, na.rm=TRUE))
  expect_true(all(bodysizedata$hfl <= bodysizedata$maxhfl, na.rm=TRUE))
  expect_true(all(bodysizedata$wgt >= bodysizedata$minwgt, na.rm=TRUE))
  expect_true(all(bodysizedata$wgt <= bodysizedata$maxwgt, na.rm=TRUE))
  
})
  
test_that("new tag indicators are *", {
    
    expect_true(all(na.omit(data$note2) == "*"))
    expect_true(all(na.omit(data$note3) == "*"))
    
  })  

test_that("special trapping codes (note4 and note5) are valid", {
  
  expect_true(all(na.omit(data$note4) %in% c("UT","TE","TA","TL","TR","TB")))
  expect_true(all(na.omit(data$note5) %in% c("E","R","D")))

})

test_that("no data are duplicated", {
  
  expect_true(sum(duplicated(data))==0)
  
})


