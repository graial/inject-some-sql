#!/bin/bash
set -e -x

if [ ${GITHUB_REF##*/} = "gh-pages" ]
then
  exit
fi

echo "Checking results"
test -f tmp/index.html
test -f tmp/rails3.html
test -f tmp/rails4.html
test -f tmp/rails5.html
test -f tmp/rails6.html
test -f tmp/rails8.html

if [ ${GITHUB_REF##*/} = "master" ]
then
  git reset --hard
  git checkout gh-pages
  rm -rf assets
  mv tmp/* .
  rm -rf tmp

  git config --local user.email "action@github.com"
  git config --local user.name "GitHub Action"

  git add index.html rails3.html rails4.html rails5.html rails6.html rails8.html assets/
  git -c user.name="GitHub Actions" -c user.email="noreply@github.com" commit \
          --author="github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>" \
          -m "Automated build at $(date -u)"

  git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
  git push origin gh-pages

  echo "Pushed changes to site"
else
  echo "Build appears to have succeeded"
fi
