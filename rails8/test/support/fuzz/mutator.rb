# Seeded, replayable mutation of the fuzz corpus (see CONTEXT.md: "Mutation run").
module Fuzz
  class Mutator
    FRAGMENTS = [
      "'", "''", "\"", "\\", ";", "--", "/*", "*/", "$$", "%27", "%00", "\u0000",
      "\r\n", "ʼ", "＇", "); DELETE FROM solid_cache_entries; --",
      "' OR '1'='1", " UNION SELECT 1 --", "\x04\x08", "<script>", "\\x27"
    ].freeze

    OPERATIONS = %i[
      insert_fragment replace_fragment double_up truncate upcase_random repeat
      splice wrap_dollar url_encode_quotes prepend_fragment append_fragment
    ].freeze

    attr_reader :seed

    def initialize(seed)
      @seed = seed
      @rng = Random.new(seed)
    end

    # Returns `count` mutated strings. With binary: true raw bytes may be
    # flipped (for the cache API); otherwise every result is valid UTF-8 so it
    # can travel as an HTTP parameter.
    def mutations(count, bases: CORPUS, binary: false)
      Array.new(count) do
        s = bases[@rng.rand(bases.size)].dup
        (1 + @rng.rand(4)).times { s = apply(OPERATIONS[@rng.rand(OPERATIONS.size)], s, bases) }
        s = flip_byte(s) if binary && @rng.rand(4).zero?
        binary ? s : s.dup.force_encoding("UTF-8").scrub
      end
    end

    private

    def apply(op, s, bases)
      s = s.dup.force_encoding("UTF-8").scrub
      case op
      when :insert_fragment  then s.dup.insert(@rng.rand(s.length + 1), fragment)
      when :replace_fragment then s.empty? ? fragment : s.dup.tap { |t| t[@rng.rand(t.length)] = fragment }
      when :double_up        then s + s
      when :truncate         then s[0, @rng.rand(s.length + 1)]
      when :upcase_random    then s.chars.map { |c| @rng.rand(2).zero? ? c.swapcase : c }.join
      when :repeat           then s * (2 + @rng.rand(40)) # stays small enough for HTTP params
      when :splice           then s + bases[@rng.rand(bases.size)].dup.force_encoding("UTF-8").scrub
      when :wrap_dollar      then "$$#{s}$$"
      when :url_encode_quotes then s.gsub("'", "%27").gsub('"', "%22")
      when :prepend_fragment then fragment + s
      when :append_fragment  then s + fragment
      end
    end

    def fragment
      FRAGMENTS[@rng.rand(FRAGMENTS.size)]
    end

    def flip_byte(s)
      b = s.b
      return b if b.empty?
      b.setbyte(@rng.rand(b.bytesize), @rng.rand(256))
      b
    end
  end
end
