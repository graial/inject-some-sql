#!/bin/bash
set -e -x

if [ ${GITHUB_REF##*/} = "gh-pages" ]
then
  exit
fi

rm -rf tmp/
mkdir tmp
mkdir tmp/assets

export RAILS_ENV=production

gem install bundler -v"1.17.3"

cd rails3
bundle install --jobs 4 --retry 3
bundle exec rake assets:precompile
bundle exec rake db:reset
bundle exec rake db:setup
bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails3.html
cp -rf localhost\:3000/assets/* ../tmp/assets/
rm -rf localhost\:3000
cd ..

echo "NOW RAILS 4"

cd rails4
bundle install --jobs 4 --retry 3
bundle exec rake assets:precompile
bundle exec rake db:reset
bundle exec rake db:setup
bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails4.html
cp -rf localhost\:3000/assets/* ../tmp/assets/
rm -rf localhost\:3000
cd ..

echo "NOW RAILS 5"

cd rails5
bundle install --jobs 4 --retry 3

export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
RAILS_ENV=production bundle exec rails assets:clobber
RAILS_ENV=production bundle exec rails assets:precompile
rails db:environment:set RAILS_ENV=production
RAILS_ENV=production bundle exec rails db:reset
RAILS_ENV=production bundle exec rails db:setup
RAILS_ENV=production bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails5.html
cp localhost\:3000/examples ../tmp/index.html
cp -rf localhost\:3000/assets/* ../tmp/assets/
rm -rf localhost\:3000
cd ..

echo "NOW RAILS 6"

cd rails6
gem install bundler -v"2.2.21"
bundle install --jobs 4 --retry 3

RAILS_ENV=production bundle exec rails assets:clobber
RAILS_ENV=production bundle exec rails assets:precompile
RAILS_ENV=production rails db:environment:set RAILS_ENV=production
RAILS_ENV=production bundle exec rails db:schema:load
RAILS_ENV=production bundle exec rails db:seed
RAILS_ENV=production bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails6.html
cp localhost\:3000/examples ../tmp/index.html
cp -rf localhost\:3000/assets/* ../tmp/assets/
rm -rf localhost\:3000
cd ..

# rails8 is generated separately (generate-github-rails8.sh), under its own
# Ruby version and against Postgres, then published by generate-github-publish.sh.
