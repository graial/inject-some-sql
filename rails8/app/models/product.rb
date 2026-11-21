class Product < ApplicationRecord
  validates :title, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :title, uniqueness: true

  after_commit -> { ReindexProductJob.perform_later(self) }, on: [ :create, :update ]

  # Low-level caching example (bound, safe): used by StoreController's
  # ?q= search.
  def self.cached_search(term)
    Rails.cache.fetch([ "product_search", term ], expires_in: 5.minutes) do
      where("title LIKE ?", "%#{sanitize_sql_like(term)}%").order(:title).pluck(:id)
    end
  end

  # Cache-inspection helper (UNSAFE - see README / query#examples "Solid
  # Cache"). A plausible admin/debug tool: "find cache entries whose key
  # contains this substring". The substring is interpolated directly into the
  # SQL string, which then runs against the cache database's own connection
  # (solid_cache_entries lives in a separate database from `products`, so the
  # SQL has to run on SolidCache::Entry's connection to reach it at all).
  #
  # On Postgres, connection.select_all sends the whole string as one round
  # trip via the simple query protocol, which runs every ';'-separated
  # statement it contains.
  def self.unsafe_cache_entries_matching(key_fragment)
    sql = "SELECT key, key_hash, byte_size FROM solid_cache_entries WHERE key LIKE '%#{key_fragment}%' ORDER BY id DESC LIMIT 5"
    SolidCache::Entry.connection.select_all(sql).to_a
  end
end
