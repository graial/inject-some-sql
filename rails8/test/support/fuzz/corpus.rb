# Curated fuzz corpus (see CONTEXT.md: "Fuzz corpus").
#
# These are hostile strings. They are only ever sent to the throwaway Postgres
# cache database created by `bin/rails test:security`.
module Fuzz
  # Payloads that, if concatenated into a statement, close a literal and run a
  # second statement against the cache table. The positive control must be
  # flagged by the oracle for every one of these.
  STACKED = [
    "x'); DELETE FROM solid_cache_entries; --",
    "x'); DROP TABLE solid_cache_entries; --",
    "x'); TRUNCATE solid_cache_entries; --",
    "x'); UPDATE solid_cache_entries SET value = '\\x0408'; --",
    "x', 'y', 1, 1, now()); INSERT INTO solid_cache_entries (key, value, key_hash, byte_size, created_at) VALUES ('evil', '\\x0408', 424242, 2, now()); --",
    "x'); SELECT pg_sleep(0.01); --",
    "x'); COPY (SELECT 1) TO PROGRAM 'true'; --",
    "x'); CREATE TABLE fuzz_pwned (id int); --",
    "x'; DELETE FROM solid_cache_entries WHERE '1'='1",
    "'; DELETE FROM solid_cache_entries; --",
    "\\'); DELETE FROM solid_cache_entries; --",
    "x$$); DELETE FROM solid_cache_entries; --$$"
  ].freeze

  CORPUS = (STACKED + [
    # --- plain / structural ------------------------------------------------
    "",
    " ",
    "a",
    "MyString",
    "0",
    "-1",
    "1e999",
    "NaN",
    "null",
    "true",
    # --- quote and escape breakers -----------------------------------------
    "'",
    "''",
    "\"",
    "`",
    "\\",
    "\\'",
    "' OR '1'='1",
    "' OR 1=1 --",
    "\" OR \"\"=\"",
    "') OR ('1'='1",
    "'; --",
    "'/**/OR/**/1=1--",
    "admin'--",
    # --- UNION / blind / time ----------------------------------------------
    "' UNION SELECT NULL, NULL, NULL --",
    "' UNION SELECT value, key, 1, 1, now() FROM solid_cache_entries --",
    "1 UNION SELECT password_digest FROM users",
    "1; SELECT pg_sleep(1)",
    "' AND (SELECT 1 FROM pg_sleep(0.01)) IS NOT NULL --",
    "' AND 1=(SELECT COUNT(*) FROM solid_cache_entries) --",
    "1' AND SLEEP(1) --",
    "'||(SELECT version())||'",
    # --- Postgres specifics ------------------------------------------------
    "$$",
    "$$; DELETE FROM solid_cache_entries; --",
    "$tag$ x $tag$",
    "E'\\x27; DELETE FROM solid_cache_entries; --'",
    "U&'\\0027'",
    "\\x27; DELETE FROM solid_cache_entries; --",
    "'::bytea",
    "'||chr(39)||'",
    "%27; DELETE FROM solid_cache_entries; --",
    # --- LIKE / pattern chars ----------------------------------------------
    "%",
    "_",
    "%' OR title LIKE '%",
    # --- encoding and control bytes ----------------------------------------
    "\u0000",
    "a\u0000b'; DELETE FROM solid_cache_entries; --",
    "\r\n'; DELETE FROM solid_cache_entries; --",
    "ʼ; DELETE FROM solid_cache_entries; --",  # modifier letter apostrophe
    "＇; DELETE FROM solid_cache_entries; --",  # fullwidth apostrophe
    "‮'; DELETE FROM solid_cache_entries",     # RTL override
    "é" * 300,
    "😀'; DROP TABLE solid_cache_entries; --",
    # --- Marshal / serializer prefixes (threat model #2) -------------------
    "\x04\x08".b.force_encoding("UTF-8").scrub,
    "\x04\bI\"\x06a\x06:\x06ET".b.force_encoding("UTF-8").scrub,
    "\x00\x11\x02".b.force_encoding("UTF-8").scrub,
    # --- cache-key shaped inputs -------------------------------------------
    "views/store/index:abc/products/1-20260101000000000000",
    "../../etc/passwd",
    "key with spaces",
    "a/b/c",
    "x" * 1024,
    "x" * 1025,
    # --- markup / XSS for the rendered fragments ---------------------------
    "<script>alert(1)</script>",
    "<img src=x onerror=alert(1)>",
    "\"><svg onload=alert(1)>",
    "<b onmouseover=alert(1)>bold</b>",
    "javascript:alert(1)",
    "{{7*7}}",
    "<%= 7*7 %>",
    "\#{7*7}",
    # --- sanitizer parser limits (regression: stored DoS on the store page) ---
    "<b>" * 600,
    "<i<sCripT>G SRC=X OnerrOR=aLert(1)>" * 600
  ]).uniq.freeze
end
