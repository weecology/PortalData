


#
# determines if a tag is a PIT tag by its structure
#  requires species input for comparison, returns a logical vector
#
PIT_tag <- function(tag, species){
  tagchar <- nchar(tag)
  sp_in_tag <- substr(tag, 5, 6) == as.character(species)
  non_pit_letters <- grepl("[HIMNOPRSTUX]", tag)
  out <- rep(FALSE, length(tagchar))
  out[which(tagchar == 6 &! sp_in_tag &! non_pit_letters)] <- TRUE
  out
}

# uses general heuristics to clean the raw rodent observations
# returns a rodents data frame with a new id column 
#
# assumes 
#   all 0 and -1 tags were equivalent to NAs
#   individuals with note4 = TA and no tag were tagged but not read
#   PIT tags are not repeated among individuals
#   tag 1782: OT, OT, OL, OT should have been all OT
#   repeated tags across species were different individuals
#   either note5 = D or note2/note3 = * could be used to indicate changing
#    individuals with the same tag number
#   a gap of more than a year with no captures means that the reused number
#    is a new individual (i.e. no individuals go missing for > 1 year and then
#    are found again)
#   an individual can only be captured in one plot per day
#     if a tag number shows up in multiple plots in a day, 
#     the replicate from the more commonly visited plot for the individual is
#     kept. if it's a tie, the first observation is the one that's kept
#     if they are in the same plot (weird!) the first one is kept
#
# individuals without tag ids are given arbitrary number ids, starting with
#   a number 1000 larger than the largest number tag in the database
#   letters and ?s are translated to 0s
#
clean_tags <- function (rodents, clean = TRUE, quiet = FALSE) {

  if (!clean) {

    return(rodents)

  }

  if (!quiet) {

    message("Cleaning tag data...")

  }

  # append the tag type
  rodents$pit_tag <- PIT_tag(rodents$tag, rodents$species)

  # replace all 0 and -1 tags with NAs
  rodents$tag[which(rodents$tag == 0)] <- NA
  rodents$ltag[which(rodents$ltag == 0)] <- NA
  rodents$tag[which(rodents$tag == -1)] <- NA
  rodents$ltag[which(rodents$ltag == -1)] <- NA

  # remove any asterisks where tag is NA
  rodents$note2[which(rodents$note2 == "*" & is.na(rodents$tag))] <- NA
  rodents$note3[which(rodents$note3 == "*" & is.na(rodents$ltag))] <- NA

  # create ID column
  rodents$id <- rodents$tag

  # remove individuals with TA in note4 and no tag, as they were tagged but
  #  the tag wasn't read so it's not a new ind
  TAs <- which(rodents$note4 == "TA" & is.na(rodents$tag))
  rodents <- rodents[-TAs, ]

  # give an id to individuals with no id
  unks <- which(is.na(rodents$tag) == TRUE)
  nunks <- length(unks)

  temp <- gsub("([[:alpha:]])", "0", rodents$tag)
  temp <- gsub("\\?", "0", temp)
  max_id <- max(as.numeric(na.omit(temp)), na.rm = TRUE)
  start_id <- max_id + 1000

  end_id <- start_id + nunks - 1
  rodents$id[unks] <- start_id:end_id
  # disentangle non-unique ids
  # making the assumption that PIT tag values are not repeated among 
  # individuals

  # split based on species code within tag

  rodents$id <- paste0(rodents$id, "_", rodents$species) 
    
  # for a given tag and species, there still could be multiple individuals
  # break a set apart based either on note5 == "D" ("dead") or 
  # note2/note3 == * (new individual) 

  uids <- unique(rodents$id)
  nuids <- length(uids)
  
  rodents$status <- ""
  rodents$status[rodents$note2 == "*" | rodents$note3 == "*"] <- "*"
  rodents$status[rodents$note5 == "D"] <- "D"
  rodents$id_status <- paste(rodents$id, rodents$status, sep = "_")


  ast <- rodents$note2 == "*"
  D <- rodents$note5 == "D"

  rodents$date <- as.Date(apply(rodents[, c("year", "month", "day")], 1, 
                                paste, collapse = "-"))

  rodents <- rodents[order(rodents$species, rodents$id, rodents$date), ]

  rodents$idind <- 1


  fun1 <- function(x){
    x[length(x)] <- "D"
    x[1] <- "*"
    x[(which(x == "*") - 1)] <- "D"
    x[1] <- "*"
    x
  }

  fun2 <- function(x){
    nx <- sum(x == "*")
    x[x == "*"] <- 1:nx
    x[!(x %in% 1:nx)] <- 0
    rep(1:sum(x %in% 1:nx), 
        diff(c(which(x %in% 1:nx), length(x) + 1)))
  }



  for(i in 1:nuids){

    if(sum(rodents$id == uids[i]) == 1){
      next()
    }

    rodents$status[rodents$id == uids[i]] <- 
                            fun1(rodents$status[rodents$id == uids[i]])
    rodents$idind[rodents$id == uids[i]] <- 
                            fun2(rodents$status[rodents$id == uids[i]])

  }


  rodents$id_ind <- paste(rodents$id, rodents$idind, sep = "_")



  # or an extended time window break for non-PIT tags
  #  assuming that if there's a gap of more than 1 year between records
  #  for a non-PIT tag, then that means it's a new individual

  uids <- unique(rodents$id_ind)
  nuids <- length(uids)
  sp <- rep(NA, nuids)
  PIT_tagYN <- rep(NA, nuids)
  longev <- rep(NA, nuids)
  for(i in 1:nuids){
    rodents_i <- rodents[which(rodents$id_ind == uids[i]),]
    rid <- paste0(rodents_i$year, "-", rodents_i$month, "-", rodents_i$day)
    rid <- as.Date(rid)
    sp[i] <- rodents_i$species[1]
    PIT_tagYN[i] <- rodents_i$pit_tag[1]
    longev[i] <- as.numeric(difftime(max(rid), min(rid), unit = "days"))/365
  }



  whichlong <- which(longev > 1 & !PIT_tagYN)
  nlong <- length(whichlong)
  for(i in 1:nlong){
    longuid <- uids[whichlong[i]]
    rodents_i <- rodents[which(rodents$id_ind == longuid),]
    rid <- paste0(rodents_i$year, "-", rodents_i$month, "-", rodents_i$day)
    rid <- as.Date(rid)
    ddiff <- c(0, as.numeric(diff(rid))/365)
    ind <- rep(NA, NROW(rodents_i))
    newind <- c(1, which(ddiff > 1))
    nnewind <- length(newind)
    lastofind <- c(newind - 1, NROW(rodents_i))
    lastofind <- lastofind[lastofind > 0]
    for(j in 1:nnewind){
      spot1 <- newind[j]
      spot2 <- lastofind[j]
      ind[spot1:spot2] <- j
    }
    rodents_i$id_ind <- paste0(rodents_i$id_ind , "_", letters[ind])
    rodents[which(rodents$id_ind == uids[whichlong[i]]),] <- rodents_i    
  }



  # remove duplicates from the same date
  #  choosing the duplicate that is from a more common plot for the individual
  #  if it's a tie, the first observation is the one that keeps the ID
  #  the other record gets no individual ID

  uids <- unique(rodents$id_ind)
  nuids <- length(uids)
  for(i in 1:nuids){
    rodents_i <- rodents[which(rodents$id_ind == uids[i]),]
    pds <- table(rodents_i$date)
    if(any(pds > 1)){
      mpds <- which(pds > 1)
      plts <- table(rodents_i$plot)/NROW(rodents_i)
      for(j in 1:length(mpds)){
        pd_j <- names(mpds)[j]
        uplts <- rodents_i$plot[rodents_i$date == pd_j]
        to_keep <- uplts[which(uplts == names(plts)[which.max(plts)])]
        if(length(to_keep) == 0){
          to_keep <- uplts[1]
          to_drop <- which(rodents_i$date == pd_j & 
                           rodents_i$plot != to_keep)        
          to_drop_RID <- rodents_i$recordID[to_drop]
        } else if (length(to_keep) == 1){
          to_drop <- which(rodents_i$date == pd_j & 
                           rodents_i$plot != to_keep)        
          to_drop_RID <- rodents_i$recordID[to_drop]
        } else {
          to_drop <- which(rodents_i$date == pd_j)[-1]
          to_drop_RID <- rodents_i$recordID[to_drop]
        }
        rodents$id_ind[which(rodents$recordID %in% to_drop_RID)] <- NA
      }
    }

  }

  if (!quiet) {

    message("...tag data cleaned")

  }
  rodents$id <- rodents$id_ind

  rodents  %>%
    dplyr::mutate(id = ifelse(is.na(species), NA, id),
                  pit_tag = ifelse(is.na(species), NA, pit_tag)) %>%
    dplyr::select(-c(status, id_ind, idind, id_status, date)) %>%
    dplyr::arrange(recordID)
}
