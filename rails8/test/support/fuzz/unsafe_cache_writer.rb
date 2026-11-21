# POSITIVE CONTROL - INTENTIONALLY VULNERABLE. TEST SUPPORT ONLY.
#
# Interpolates attacker input straight into SQL against the cache table. It
# exists solely to prove the oracle can see a real injection (CONTEXT.md:
# "Positive control"), independent of Product.unsafe_cache_entries_matching
# (the app's own demonstration method, exercised separately in
# low_level_cache_fuzz_test.rb). Never required by app code; must never be
# moved out of test/support.
module Fuzz
  module UnsafeCacheWriter
    module_function

    # A vulnerable lookup on the PRIMARY (app) database, e.g. a search.
    def search_products(term)
      ActiveRecord::Base.connection.execute(
        "SELECT id FROM products WHERE (title LIKE '%#{term}%')"
      )
    end

    # A vulnerable cache lookup. Postgres' simple-query protocol runs stacked
    # statements, so `x'); DELETE FROM solid_cache_entries; --` really executes.
    def lookup(key)
      SolidCache::Entry.connection.execute(
        "SELECT value FROM solid_cache_entries WHERE (key = '#{key}')"
      )
    end
  end
end
