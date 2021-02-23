#' Bump version based on version instructions in commit
#' or automatically for cron jobs


bump_version <- function(history, cron) {

current_ver <- semver::parse_version(readLines("version.txt"))

if (cron==TRUE) {
  
# Cron job, increment minor version
new_ver <- semver::increment_version(current_ver, "minor", 1L)

} else { # this is triggered by an update to Main or by a PR on a branch
  # parse the most recent commit for version instructions 
  last_commit <- history[[1]]
  if (grepl("Merge", last_commit['summary'], ignore.case = TRUE))
  {
    last_commit <- history[[2]]
  }
  
  if (grepl("\\[no version bump\\]", last_commit['summary'], ignore.case = TRUE))
  {
    new_ver <- current_ver
  } else if (grepl("\\[major\\]", last_commit['summary'], ignore.case = TRUE)) {
    new_ver <- semver::increment_version(current_ver, "major", 1L)
  } else if (grepl("\\[minor\\]", last_commit['summary'], ignore.case = TRUE)) {
    new_ver <- semver::increment_version(current_ver, "minor", 1L)
  } else if (grepl("\\[patch\\]", last_commit['summary'], ignore.case = TRUE)) {
    new_ver <- semver::increment_version(current_ver, "patch", 1L)
  } else {
    stop(paste("The final commit message in a set of changes must be tagged",
               "with version increment information.\nOptions include",
               "[major], [minor], [patch], and [no version bump].\n",
               "The last commit in this set of changes is:\n",
               last_commit['summary']))
  }
}

writeLines(as.character(new_ver), "version.txt") 
}
