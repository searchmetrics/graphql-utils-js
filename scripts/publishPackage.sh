#!/bin/bash
set -e

current_version=$(node -p "require('./package').version")

printf "Next version (current is $current_version)? "
read next_version

if ! [[ $next_version =~ ^[0-9]\.[0-9]+\.[0-9](-.+)? ]]; then
  echo "Version must be a valid semver string, e.g. 1.0.2 or 2.3.0-beta.1"
  exit 1
fi

# npm test -- --single-run
echo "$(node -p "p=require('./package.json');p.version='${next_version}';JSON.stringify(p,null,2)")" > 'package.json'
sed -i.DELETEME -e "s/version = '$current_version';/version = '$next_version';/g" src/*.js
rm src/*.js.DELETEME
echo "Updated version to ${next_version}"

#!/usr/bin/env bash
#capture the results of the tests
echo "Running tests"

TESTS=$(npm run test 2>&1)

#filter and find errors and warnings
ERR=$(echo $TESTS \
  | awk '/ERR! Exit status 1|Failed/' \
  | wc -l| tr -d ' ')

#decide what to do with the errors if any
if [ "$ERR" == "0" ]; then
  echo "Tests are OK!"
  #go to next task
  else
    echo -e $TESTS
    echo  -e "\n\n=========\nPlease fix $ERR warnings or errors before push\\nRun: npm run test --reporter min\n=========";
    exit 1;
fi

git add -A

read -p "Are you ready to publish? [Y/n] " -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! $REPLY == "" ]]
then
  echo "Exit by user"
  exit 1
fi

git commit -m "Version $next_version"

next_ref="v$next_version"

git tag "$next_ref"
git tag latest -f

git push -f origin master
git push origin "$next_ref"
git push origin latest -f

npm publish
