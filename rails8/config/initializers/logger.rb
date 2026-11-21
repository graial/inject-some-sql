if not defined? ActiveRecord::ConnectionAdapters::AbstractAdapter
  abort "Need to be able to override AbstractAdapter log"
end

class ActiveRecord::ConnectionAdapters::AbstractAdapter
  alias oldlog log

  # Postgres additionally logs its own type-cache lookups (queries against
  # pg_type/pg_attribute), which SQLite never does; skip those too so $last_sql
  # reflects the example's own query, not driver internals.
  def log sql, *args, **kwargs, &block
    $last_sql = sql unless sql.include?("transaction") || sql.include?("pg_type") || sql.include?("pg_attribute")
    oldlog sql, *args, **kwargs, &block
  end
end
