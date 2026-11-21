#!/bin/bash --login
set -e

#git checkout master
rm -rf tmp/
mkdir tmp
mkdir tmp/assets
export RAILS_ENV=production
export USE_RUBY=2.5.5
rvm install $USE_RUBY
rvm $USE_RUBY gemset create iss

rvm --force $USE_RUBY@iss gemset empty
rvm $USE_RUBY@iss do gem install bundler
cd rails3
rvm $USE_RUBY@iss do bundle install
rvm $USE_RUBY@iss do bundle exec rake assets:precompile
rvm $USE_RUBY@iss do bundle exec rake db:reset
rvm $USE_RUBY@iss do bundle exec rake db:setup
rvm $USE_RUBY@iss do bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails3.html
cp -rf localhost\:3000/assets/* ../tmp/assets/
rm -rf localhost\:3000
cd ..

echo "NOW RAILS 4"

rvm --force $USE_RUBY@iss gemset empty
rvm $USE_RUBY@iss do gem install bundler
cd rails4
rvm $USE_RUBY@iss do bundle install
rvm $USE_RUBY@iss do bundle exec rake assets:precompile
rvm $USE_RUBY@iss do bundle exec rake db:reset
rvm $USE_RUBY@iss do bundle exec rake db:setup
rvm $USE_RUBY@iss do bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails4.html
cp -rf localhost\:3000/assets/* ../tmp/assets/
rm -rf localhost\:3000
cd ..

echo "NOW RAILS 5"
export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
rvm --force $USE_RUBY@iss gemset empty
rvm $USE_RUBY@iss do gem install bundler
cd rails5
rvm $USE_RUBY@iss do bundle install
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails assets:clobber
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails assets:precompile
RAILS_ENV=production rvm $USE_RUBY@iss do rails db:environment:set RAILS_ENV=production
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails db:reset
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails db:setup
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails5.html
cp -rf localhost\:3000/assets/* ../tmp/assets/
rm -rf localhost\:3000
cd ..

echo "NOW RAILS 6"

rvm --force $USE_RUBY@iss gemset empty
rvm $USE_RUBY@iss do gem install bundler
cd rails6
rvm $USE_RUBY@iss do bundle install
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails assets:clobber
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails assets:precompile
RAILS_ENV=production rvm $USE_RUBY@iss do rails db:environment:set RAILS_ENV=production
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails db:schema:load
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails db:seed
RAILS_ENV=production rvm $USE_RUBY@iss do bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails6.html
cp localhost\:3000/examples ../tmp/index.html
cp -rf localhost\:3000/assets/* ../tmp/assets/
rm -rf localhost\:3000
cd ..

echo "NOW RAILS 8"

# Uses rbenv instead of rvm (rails8/.ruby-version pins 3.4.5). Set
# ISS_RUBY8_VERSION to a different rbenv version name - e.g. a custom-patched
# build registered under ~/.rbenv/versions/ - to use that instead.
# Needs a local Postgres; see rails8/README.md.
export RBENV_VERSION="${ISS_RUBY8_VERSION:-3.4.5}"
cd rails8
rbenv exec gem install bundler --conservative
rbenv exec bundle install
RAILS_ENV=production rbenv exec bundle exec rails db:create db:schema:load
RAILS_ENV=production rbenv exec bundle exec rails db:seed
RAILS_ENV=production rbenv exec bundle exec rails s &
sleep 10
wget -p http://localhost:3000/examples
kill %1
cp localhost\:3000/examples ../tmp/rails8.html
cp -rf localhost\:3000/assets/* ../tmp/assets/ 2>/dev/null || true
rm -rf localhost\:3000
cd ..
unset RBENV_VERSION

git reset --hard
git checkout gh-pages
rm -rf assets
mv tmp/* .
rm -rf tmp

git add index.html rails3.html rails4.html rails5.html rails6.html rails8.html assets/
echo "To deploy:"
echo "git commit && git push"
