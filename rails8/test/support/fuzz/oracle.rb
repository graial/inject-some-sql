# The oracle (see CONTEXT.md): decides whether an injection succeeded.
#
#   1. Integrity   - the sentinel row, the schema and the products table are untouched.
#   2. SQL shape   - payload bytes never appear raw in SQL text, and once hex
#                    literals and bind markers are stripped, a cache statement
#                    has no stray quote, ';' or comment left to carry a payload.
#   3. Inert read  - asserted by the tests themselves (round-trip / escaping).
#
# NB: Solid Cache writes with upsert_all, which inlines key/value as bytea hex
# literals ('\x7465...') rather than binds, so "only in binds" is the wrong
# invariant; "only as an inert hex literal or bind" is the right one.
module Fuzz
  class Oracle
    SENTINEL_KEY = "fuzz:sentinel".freeze
    SENTINEL_VALUE = "sentinel-value".freeze
    HEX_LITERAL = /'\\x[0-9a-fA-F]*'/
    IGNORED_EVENT_NAMES = %w[SCHEMA TRANSACTION].freeze

    Event = Struct.new(:name, :sql)

    attr_reader :events

    def initialize
      @events = []
      @sentinel_row = nil
      @tables = nil
    end

    # --- capture --------------------------------------------------------------

    def capture
      @events = []
      sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        next if IGNORED_EVENT_NAMES.include?(payload[:name]) || payload[:cached]
        @events << Event.new(payload[:name], payload[:sql].to_s)
      end
      yield
    ensure
      ActiveSupport::Notifications.unsubscribe(sub) if sub
    end

    # --- sentinel / schema ------------------------------------------------------

    def plant_sentinel!
      SolidCache::Entry.delete_all
      Rails.cache.write(SENTINEL_KEY, SENTINEL_VALUE)
      rows = SolidCache::Entry.order(:id).pluck(:id, :key, :value)
      raise "expected exactly one sentinel row, got #{rows.size}" unless rows.size == 1
      @sentinel_row = rows.first
      @tables = tables_snapshot
      @products = products_snapshot
    end

    def sentinel_intact?
      SolidCache::Entry.where(id: @sentinel_row[0]).pluck(:id, :key, :value) == [ @sentinel_row ]
    rescue ActiveRecord::StatementInvalid
      false
    end

    def schema_intact?
      tables_snapshot == @tables
    rescue ActiveRecord::StatementInvalid
      false
    end

    def products_intact?
      products_snapshot == @products
    rescue ActiveRecord::StatementInvalid
      false
    end

    # --- verdict ----------------------------------------------------------------

    # Returns an array of human-readable violations (empty means the payload was
    # handled safely).
    def violations_for(payload, events: @events)
      found = []
      events.each do |e|
        found.concat(sql_shape_violations(e, payload))
      end
      found << "sentinel cache row missing or altered" unless sentinel_intact?
      found << "table list changed (table dropped or created)" unless schema_intact?
      found << "products table altered or emptied" unless products_intact?
      found
    end

    def sql_shape_violations(event, payload)
      sql = event.sql
      out = []
      pb = payload.to_s.b
      # Purely alphanumeric payloads cannot break out of a literal, and would
      # false-positive on digit runs inside hex literals / key_hash values.
      stripped = sql.gsub(HEX_LITERAL, "?")
      if pb.bytesize >= 4 && !pb.match?(/\A[[:alnum:]]*\z/) && stripped.b.include?(pb)
        out << "payload appears raw in SQL: #{sql[0, 200].inspect}"
      end

      return out unless sql.include?("solid_cache_entries")

      skeleton = sql.gsub(HEX_LITERAL, "?")
      out << "stray quote outside hex literal: #{skeleton[0, 200].inspect}" if skeleton.include?("'")
      out << "statement separator: #{skeleton[0, 200].inspect}" if skeleton.include?(";")
      out << "comment marker: #{skeleton[0, 200].inspect}" if skeleton.match?(%r{--|/\*})
      out << "unexpected statement type: #{skeleton[0, 80].inspect}" unless skeleton.match?(/\A\s*(SELECT|INSERT|DELETE|UPDATE)\b/i)
      out
    end

    private

    def products_snapshot
      Product.order(:id).pluck(:id, :title, :price)
    end

    def tables_snapshot
      [ ActiveRecord::Base.connection, SolidCache::Entry.connection ].map { |c| c.tables.sort }
    end
  end
end
