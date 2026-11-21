Queries = [
  {
    :action => :solid_cache_entry_write,
    :name => "Cache-Entry Write (Product.unsafe_cache_entries_matching)",
    :link => "https://guides.rubyonrails.org/caching_with_rails.html#low-level-caching",
    :query => 'Product.unsafe_cache_entries_matching(params[:key]); SolidCache::Entry.order(id: :desc).limit(3).pluck(:key, :key_hash, :byte_size, :created_at)',
    :input => {
      :name => :key,
      :example => "x'; INSERT INTO solid_cache_entries (key, value, key_hash, byte_size, created_at) VALUES ('poisoned-key', '\\x0102', 918273645, 2, now()); --"
    },
    :example => "The input value closes the string literal in the method's `WHERE key LIKE` clause, adds a second statement that inserts a row directly into `solid_cache_entries` with key `poisoned-key`, and comments out the remainder of the original statement. The result lists the most recent `solid_cache_entries` rows, including the one just inserted.",
    :desc => <<-MD
`Product.unsafe_cache_entries_matching(key_fragment)` builds its SQL by interpolating `key_fragment` directly into a string, rather than binding it, then runs that string with `SolidCache::Entry.connection.select_all`.

On Postgres, `select_all` sends the whole string in one round trip using the simple query protocol, which executes every ';'-separated statement it contains - including statements against `solid_cache_entries`, the table Solid Cache itself reads from and writes to. The query runs on the cache database's own connection, since `solid_cache_entries` lives in a separate database from the application's other tables in this app's multi-database setup.

This requires a stacked-statement-capable database connection. SQLite executes only the first statement in a string and silently drops the rest, so this example needs Postgres (see the repo README).
    MD
  }
].freeze
