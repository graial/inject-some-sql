require_relative "corpus"
require_relative "mutator"
require_relative "oracle"
require_relative "unsafe_cache_writer"
require_relative "marker"

module Fuzz
  def self.seed
    (ENV["FUZZ_SEED"] || Minitest.seed).to_i
  end

  def self.iterations
    Integer(ENV.fetch("FUZZ_ITERATIONS", "200"))
  end

  def self.replay_hint
    "replay with: FUZZ_SEED=#{seed} FUZZ_ITERATIONS=#{iterations} bin/rails test:security"
  end

  # Base class: IntegrationTest, skipped unless run via `bin/rails test:security`
  # (FUZZ=1), with real fragment caching on and a seeded oracle.
  class TestCase < ActionDispatch::IntegrationTest
    setup do
      skip "fuzz suite: run `bin/rails test:security` (needs FUZZ=1 and the Postgres cache DB)" unless ENV["FUZZ"]
      unless SolidCache::Entry.connection.adapter_name.match?(/postg/i)
        flunk "fuzz suite must run against Postgres, got #{SolidCache::Entry.connection.adapter_name}"
      end

      @saved_caching = ActionController::Base.perform_caching
      ActionController::Base.perform_caching = true
      @oracle = Oracle.new
      @oracle.plant_sentinel!
    end

    teardown do
      ActionController::Base.perform_caching = @saved_caching if defined?(@saved_caching)
    end

    attr_reader :oracle

    def mutator(label = self.class.name)
      # Distinct but replayable stream per test class.
      Mutator.new(Fuzz.seed + label.to_s.sum)
    end

    def payloads(label, binary: false)
      CORPUS + mutator(label).mutations(Fuzz.iterations, binary: binary)
    end

    def assert_no_violations(payload, events: oracle.events, context: nil)
      v = oracle.violations_for(payload, events: events)
      assert_empty v, <<~MSG
        Injection oracle tripped#{" (#{context})" if context}
        payload: #{payload.inspect}
        #{v.join("\n")}
        #{Fuzz.replay_hint}
      MSG
    end
  end
end
