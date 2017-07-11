git config --global user.email "weecologydeploy@weecology.org"
git config --global user.name "Weecology Deploy Bot"

git checkout master
git add -u
git commit -m "Update supplemental data tables: Travis Build $TRAVIS_BUILD_NUMBER"

git remote add deploy https://${GITHUB_TOKEN}@github.com/weecology/PortalData.git > /dev/null 2>&1
git push --quiet deploy master > /dev/null 2>&1
