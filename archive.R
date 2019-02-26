#' Update the version number
#'

config <- yaml::yaml.load_file("config.yml")

repo <- git2r::repository(".")
repo_url <- paste("https://github.com/", config$repo, ".git", sep = "")
git2r::remote_add(repo, name = "deploy", url = repo_url)
cred <- git2r::cred_token("GITHUB_TOKEN")

# Use a special user name so that it is clear which commits are automated
git2r::config(repo,
              user.email = config$deploy_email,
              user.name = config$deploy_username)

# set up the new commit
travis_build <- Sys.getenv("TRAVIS_BUILD_NUMBER")
commit_message <- paste("Update data and trigger archive: Travis Build",
                        travis_build,
                        "[skip ci]")

# handle changes to the version number
current_ver <- semver::parse_version(readLines("version.txt"))

if (Sys.getenv("TRAVIS_EVENT_TYPE") == "cron") # is this a build triggered by Cron
{
  commit_message <- paste(commit_message, "[cron]")
  
  # check for changes to files
  git_status <- git2r::status(repo)
  if (length(git_status$staged) == 0 && 
      length(git_status$unstaged) == 0 && 
      length(git_status$untracked) == 0) # no changes to any files
  {
    new_ver <- current_ver
  } else if (length(git_status$staged) == 0 && 
             length(git_status$unstaged) > 0 && # changes to data files
             length(git_status$untracked) == 0) {
    new_ver <- semver::increment_version(current_ver, "minor", 1L)
  } else {
    stop(paste("Encountered an unexpected git status during the Cron update."))
  }
} else { # this is triggered by an update to Master or by a PR on a branch
  # parse the most recent commit for version instructions 
  last_commit <- git2r::commits(repo)[[1]]
  if (grepl("Merge", last_commit['summary'], ignore.case = TRUE))
  {
    last_commit <- git2r::commits(repo)[[2]]
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

# Create a new release to trigger Zenodo archiving

# If the version has been incremented (i.e. there are changes to be committed), 
#  this is the master branch of the repo, and 
#  this is not a pull request, then:
#  1. add a new commit with the update data to master branch
#  2. push the changes
#  3. create a new tag
#  4. push the tag
#  5. trigger a release.
if (new_ver > current_ver && 
    Sys.getenv("TRAVIS_BRANCH") == 'master' && 
    Sys.getenv("TRAVIS_PULL_REQUEST") == 'false')
{
  # write out the new version and add the commit
  github_token <- Sys.getenv("GITHUB_TOKEN")
  git2r::checkout(repo, branch = "master")
  git2r::add(repo, "*")
  git2r::commit(repo, message = commit_message)
  
  git2r::push(repo,
              name = "deploy",
              refspec = "refs/heads/master",
              credentials = cred)
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
}