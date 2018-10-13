#' Update the version number
#'
#' By default update the minor version number since most changes are new data.
#' If [major] or [patch] is in the last commit summary increment the matching
#' version instead.

repo <- git2r::repository(".")
last_commit <- git2r::commits(repo)[[1]]
current_ver <- semver::parse_version(readLines("version.txt"))
if (grepl("Merge pull request", last_commit['summary'])){
    last_commit <- git2r::commits(repo)[[2]]
}

if (grepl("\\[no version bump\\]", last_commit['summary'])) {
  new_ver <- current_ver
} else if (grepl("\\[major\\]", last_commit['summary'])) {
  new_ver <- semver::increment_version(current_ver, "major", 1L)
} else if (grepl("\\[patch\\]", last_commit['summary'])) {
  new_ver <- semver::increment_version(current_ver, "patch", 1L)
} else {
  new_ver <- semver::increment_version(current_ver, "minor", 1L)
}

writeLines(as.character(new_ver), "version.txt")
