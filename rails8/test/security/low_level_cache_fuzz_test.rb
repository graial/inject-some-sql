require "test_helper"

# CONFIRMED (not a characterization like KF-1/KF-2): Product.unsafe_cache_entries_matching
# is the app's own, deliberately-unsafe example method (app/models/product.rb,
# demonstrated at query#examples). Unlike depot8's audit of a safe-by-default
# app, this suite exists to *confirm* the known vulnerability with the same
# oracle used elsewhere, not to deny one.
class LowLevelCacheFuzzTest < Fuzz::TestCase
  test "confirmed: a stacked payload in the key fragment writes a row into solid_cache_entries" do
    payload = "x'; INSERT INTO solid_cache_entries (key, value, key_hash, byte_size, created_at) " \
      "VALUES ('fuzz-confirmed', '\\x0102', 135792468, 2, now()); --"

    oracle.capture { Product.unsafe_cache_entries_matching(payload) }

    violations = oracle.violations_for(payload)
    refute_empty violations, <<~MSG
      Expected Product.unsafe_cache_entries_matching to be flagged as vulnerable (it interpolates
      its argument into SQL run on the cache connection), but the oracle found no violations. If
      this now passes safe, the method was fixed - flip this test to assert_no_violations and update
      the README/docs/solid_cache_poisoning_threat_model.md accordingly.
    MSG

    assert SolidCache::Entry.exists?(key: "fuzz-confirmed"),
      "stacked INSERT was flagged but the row it should have written isn't there - update this test's assumptions"
  end

  test "the full fuzz corpus against the vulnerable method: tally of flagged vs inert payloads" do
    flagged = 0
    payloads(:low_level_cache).each do |payload|
      next if payload.include?("\u0000") # the pg driver refuses null bytes outright, not an injection question

      SolidCache::Entry.transaction(requires_new: true) do
        oracle.capture do
          Product.unsafe_cache_entries_matching(payload)
        rescue ActiveRecord::StatementInvalid
          nil # a syntax error still emitted the injectable statement
        end
        flagged += 1 unless oracle.violations_for(payload).empty?
        raise ActiveRecord::Rollback
      end
    end
    puts "  [fuzz] low-level cache write: #{flagged}/#{payloads(:low_level_cache).size} payloads flagged" if ENV["FUZZ_VERBOSE"]
    assert_operator flagged, :>, 0, "no payload was flagged - the fuzz run would be vacuous either way"
  end
end
