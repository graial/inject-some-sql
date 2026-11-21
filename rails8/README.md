# Rails 8 / Solid Cache

A trimmed Rails 8 app (`Product` model, a low-level cache "find cache entries"
helper, fragment caching on `products#show`, russian-doll caching on
`store#index`, and a Solid Queue job) demonstrating SQL injection reaching the
`solid_cache_entries` table that backs `Rails.cache`.

## Setup

This app needs Postgres (not just SQLite) to demonstrate the cache-poisoning
examples: SQLite only ever executes one statement per call, so a stacked
payload (`x'; INSERT INTO solid_cache_entries ...; --`) is silently inert
there. See `docs/solid_cache_poisoning_threat_model.md` at the repo root (not
published; see root README) for why that matters.

```
cd inject-some-sql/rails8
bundle install
```

### Ruby version

Pinned to the version in `.ruby-version`. To use a different build instead -
for example a custom-patched Ruby registered as a named rbenv version -
override it with `RBENV_VERSION`:

```
RBENV_VERSION=my-patched-ruby bundle install
RBENV_VERSION=my-patched-ruby bin/rails s
```

### Databases

Development uses plain SQLite (`bin/rails db:setup`). The example queries
only show their real effect against Postgres:

```
createdb inject_some_sql_rails8_production
createdb inject_some_sql_rails8_production_cache
createdb inject_some_sql_rails8_production_queue

RAILS_ENV=production SECRET_KEY_BASE=$(bin/rails secret) bin/rails db:schema:load
RAILS_ENV=production SECRET_KEY_BASE=$(bin/rails secret) bin/rails db:seed
RAILS_ENV=production SECRET_KEY_BASE=$(bin/rails secret) bin/rails s
```

By default this connects over the local Unix socket with your OS user. Set
`POSTGRES_HOST` / `POSTGRES_USER` / `POSTGRES_PASSWORD` to connect elsewhere
(e.g. in CI, where `generate-github-rails8.sh` sets them for the Postgres
service container).

## Run

```
rails s
```

Open [localhost:3000](http://localhost:3000) for the interactive query
console, or `/examples` for the same static page the generate scripts scrape.

## Confirming the vulnerability (fuzz harness)

`test/security/*` runs the same corpus/mutation/oracle approach as this
example's reference investigation (`docs/solid_cache_poisoning_threat_model.md`),
against throwaway Postgres databases:

```
bin/rails test:security
```

Replay a specific run with `FUZZ_SEED=n FUZZ_ITERATIONS=n bin/rails test:security`.
`low_level_cache_fuzz_test.rb` confirms the published example's vulnerability
(`Product.unsafe_cache_entries_matching`) is actually flagged by the oracle,
not just plausible-looking; `fuzz_harness_test.rb` proves the oracle itself
isn't blind (positive controls); `job_arguments_fuzz_test.rb` characterizes
the separate, open ActiveJob/GlobalID argument-dispatch question (no write
primitive into the queue DB is known today).

This suite is dev/CI-only and is skipped under plain `bin/rails test`.

## License

This code is made available under the MIT license, same as the rest of this repo.
