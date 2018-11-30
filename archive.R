#' Update the version number
#'
#' By default update the minor version number since most changes are new data.
#' If [major] or [patch] is in the last commit summary increment the matching
#' version instead.

config <- yaml::yaml.load_file("config.yml")

repo <- git2r::repository(".")
repo_url <- paste("https://github.com/", config$repo, ".git", sep = "")
git2r::checkout(repo, branch = "master")
git2r::remote_add(repo, name = "deploy", url = repo_url)
cred <- git2r::cred_token("GITHUB_TOKEN")

# Use a special user name so that it is clear which commits are automated
git2r::config(repo,
              user.email = config$deploy_email,
              user.name = config$deploy_username)

# Check the most recent commit for version instructions 
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

travis_build <- Sys.getenv("TRAVIS_BUILD_NUMBER")
commit_message <- paste("Update data and trigger archive: Travis Build",
                        travis_build,
                        "[skip ci]")
git2r::add(repo, "*")
git2r::commit(repo, message = commit_message)
git2r::push(repo, name = "deploy", refspec = "refs/heads/master", credentials = cred)

# Create a new release to trigger Zenodo archiving

github_token = Sys.getenv("GITHUB_TOKEN")
git2r::tag(repo, as.character(new_ver), paste("v", new_ver, sep=""))
git2r::push(repo,
            name = "deploy",
            refspec = paste("refs/tags/", new_ver, sep=""),
            credentials = cred)
api_release_url = paste("https://api.github.com/repos/", config$repo, "/releases", sep = "")
httr::POST(url = api_release_url,
           httr::content_type_json(),
           httr::add_headers(Authorization = paste("token", github_token)),
           body = paste('{"tag_name":"', new_ver, '"}', sep=''))
