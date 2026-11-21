require "test_helper"

# Proves the harness itself works, so a green fuzz run is evidence and not a
# blind oracle: the positive control MUST be flagged, and the mutator MUST be
# replayable from its seed.
class FuzzHarnessTest < Fuzz::TestCase
  test "positive control: every stacked payload is flagged by the SQL-shape oracle" do
    Fuzz::STACKED.each do |payload|
      oracle.capture do
        ActiveRecord::Base.transaction(requires_new: true) do
          Fuzz::UnsafeCacheWriter.lookup(payload)
        rescue ActiveRecord::StatementInvalid
          nil # a syntax error still emitted the injectable statement
        ensure
          raise ActiveRecord::Rollback
        end
      end
      refute_empty oracle.events.select { |e| e.sql.include?("solid_cache_entries") },
        "control did not run a statement for #{payload.inspect}"
      shape = oracle.events.flat_map { |e| oracle.sql_shape_violations(e, payload) }
      refute_empty shape, "oracle is blind to injectable SQL for #{payload.inspect}"
    end
  end

  test "positive control: a working stacked DELETE is caught by the sentinel check" do
    payload = "x'); DELETE FROM solid_cache_entries; --"
    caught = nil
    SolidCache::Entry.transaction(requires_new: true) do
      Fuzz::UnsafeCacheWriter.lookup(payload)
      caught = !oracle.sentinel_intact?
      raise ActiveRecord::Rollback
    end
    assert caught, "stacked DELETE ran but the sentinel row survived - oracle (or Postgres multi-statement) not working"
    assert oracle.sentinel_intact?, "rollback should have restored the sentinel"
  end

  test "positive control: a stacked DROP TABLE is caught by the schema check" do
    SolidCache::Entry.transaction(requires_new: true) do
      Fuzz::UnsafeCacheWriter.lookup("x'); DROP TABLE solid_cache_entries; --")
      refute oracle.schema_intact?
      raise ActiveRecord::Rollback
    end
    assert oracle.schema_intact?
  end

  test "positive control (primary DB): a stacked DELETE on app data is caught by the products check" do
    payload = "x%'); DELETE FROM products; --"
    ActiveRecord::Base.transaction(requires_new: true) do
      oracle.capture { Fuzz::UnsafeCacheWriter.search_products(payload) }
      refute oracle.products_intact?, "stacked DELETE FROM products ran but products survived - primary is not stacked-capable"
      refute_empty oracle.violations_for(payload), "oracle did not flag the primary-DB injection"
      raise ActiveRecord::Rollback
    end
    assert oracle.products_intact?
  end

  test "primary and cache databases are both Postgres" do
    assert_match(/postg/i, ActiveRecord::Base.connection.adapter_name)
    assert_match(/postg/i, SolidCache::Entry.connection.adapter_name)
  end

  test "the safe cache API is NOT flagged for the same payloads" do
    Fuzz::STACKED.each do |payload|
      oracle.capture { Rails.cache.write(payload, payload) }
      assert_no_violations(payload, context: "Rails.cache.write control group")
    end
  end

  test "mutator is deterministic for a seed and varies across seeds" do
    a = Fuzz::Mutator.new(42).mutations(50)
    b = Fuzz::Mutator.new(42).mutations(50)
    c = Fuzz::Mutator.new(43).mutations(50)
    assert_equal a, b
    refute_equal a, c
    assert a.all? { |s| s.encoding == Encoding::UTF_8 && s.valid_encoding? }
  end

  test "caching is really on and reaching the Postgres cache table (not a vacuous run)" do
    assert ActionController::Base.perform_caching
    assert_kind_of SolidCache::Store, Rails.cache
    assert_match(/postg/i, SolidCache::Entry.connection.adapter_name)
    Rails.cache.write("probe", "x")
    assert_equal "x", Rails.cache.read("probe")
    assert_operator SolidCache::Entry.count, :>=, 2
  end
end
