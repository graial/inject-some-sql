#!/bin/bash
set -e -x

# Generates rails8's static example snapshot. Runs after generate-github.sh
# (which creates tmp/), under its own Ruby version (Rails 8 needs >= 3.2,
# unlike rails3-6's pinned Ruby 2.5), and against Postgres - see
# rails8/README.md and docs/solid_cache_poisoning_threat_model.md for why
# SQLite can't demonstrate this example's cache-poisoning write primitive.

if [ ${GITHUB_REF##*/} = "gh-pages" ]
then
  exit
fi

mkdir -p tmp/assets

export RAILS_ENV=production
export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"

cd rails8
bundle install --jobs 4 --retry 3

bundle exec rails db:create db:schema:load
bundle exec rails db:seed
bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails8.html
cp -rf localhost\:3000/assets/* ../tmp/assets/ 2>/dev/null || true
rm -rf localhost\:3000
cd ..
