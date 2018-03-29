git config --global user.email "weecologydeploy@weecology.org"
git config --global user.name "Weecology Deploy Bot"

git checkout master
git add -u
git commit -m "Update supplemental data tables: Travis Build $TRAVIS_BUILD_NUMBER [skip ci]"

git remote add deploy https://${GITHUB_TOKEN}@github.com/weecology/PortalData.git > /dev/null 2>&1
git push --quiet deploy master > /dev/null 2>&1

# Create a new release to trigger Zenodo archiving
version=$(cat version.txt)
git tag $version
git push --quiet deploy --tags > /dev/null 2>&1
curl -v -i -X POST -H "Content-Type:application/json" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/weecology/PortalData/releases -d "{\"tag_name\":\"$version\"}"
