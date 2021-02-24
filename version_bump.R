#' Bump version based on version instructions in commit
#' or automatically for cron jobs
#' @param commit latest commit
#' @param cron is it a cron job (logical)
#' @param changes are there any changed files (logical)
#' 

bump_version <- function(commit, cron, changes) {

current_ver <- semver::parse_version(readLines("version.txt"))

if (cron==TRUE) {
  if (changes==TRUE) { # for cron jobs, only bump if update_data.R resulted in changed files
# Cron job with new data, increment minor version
new_ver <- semver::increment_version(current_ver, "minor", 1L)
    }
} else { # this is triggered by an update to Main or by a PR on a branch
  # parse the most recent commit for version instructions 
  
  if (grepl("\\[no version bump\\]", commit, ignore.case = TRUE))
  {
    new_ver <- current_ver
    paste("No version bump")
  } else if (grepl("\\[major\\]", commit, ignore.case = TRUE)) {
    new_ver <- semver::increment_version(current_ver, "major", 1L)
    print("Bumping major version")
  } else if (grepl("\\[minor\\]", commit, ignore.case = TRUE)) {
    new_ver <- semver::increment_version(current_ver, "minor", 1L)
    print("Bumping minor version")
  } else if (grepl("\\[patch\\]", commit, ignore.case = TRUE)) {
    new_ver <- semver::increment_version(current_ver, "patch", 1L)
    print("Bumping patch version")
  } else {
    stop(paste("The final commit message in a set of changes must be tagged",
               "with version increment information.\nOptions include",
               "[major], [minor], [patch], and [no version bump].\n",
               "The last commit in this set of changes is:\n",
               commit))
  }
}

writeLines(as.character(new_ver), "version.txt") 
  
}
