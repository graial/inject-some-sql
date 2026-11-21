namespace :test do
  desc "Run cache-poisoning / SQL-injection fuzz tests against throwaway Postgres primary/cache/queue DBs " \
       "(FUZZ_SEED=n to replay, FUZZ_ITERATIONS=n mutations per field, FUZZ_PRIMARY_DB / FUZZ_CACHE_DB / FUZZ_QUEUE_DB=name)"
  task :security do
    env = { "FUZZ" => "1", "RAILS_ENV" => "test", "PARALLEL_WORKERS" => "1" }
    sh env, "bin/rails db:create db:schema:load:primary db:schema:load:cache db:schema:load:queue"
    sh env, "bin/rails test test/security"
  end
end
