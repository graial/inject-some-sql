require "test_helper"

# Threat model KF-2 (characterization, like depot8's): ActiveJob deserializes
# an argument row by calling `.deserialize(hash)` on whatever constant it
# names (Serializers.deserialize: serializer_name.safe_constantize), and
# GlobalID calls class methods (unscoped/find) on whatever model name a
# `_aj_globalid` names. This needs a write primitive into the queue table (a
# separate DB in production, same as the cache DB); none is known in this app
# today. Only the harmless Fuzz::Marker is used.
class JobArgumentsFuzzTest < Fuzz::TestCase
  setup { Fuzz::Marker.loaded = false }

  test "KF-2: a tampered job-argument row dispatches into an attacker-named constant" do
    Fuzz::Marker.loaded = false
    ActiveJob::Arguments.deserialize([ { "_aj_serialized" => "Fuzz::Marker" } ])
    assert Fuzz::Marker.loaded, "ActiveJob no longer dispatches to an arbitrary named serializer - update KF-2 and flip this test"

    Fuzz::Marker.loaded = false
    ActiveJob::Arguments.deserialize([ { "_aj_globalid" => "gid://#{Rails.application.class.module_parent_name.underscore}/Fuzz::Marker/1" } ])
    assert Fuzz::Marker.loaded, "GlobalID no longer dispatches to an arbitrary named model - update KF-2 and flip this test"
  end

  test "job arguments: a tampered gid can swap the model type (ReindexProductJob expects a Product)" do
    product = products(:pragprog)
    args = ActiveJob::Arguments.deserialize([ { "_aj_globalid" => product.to_global_id.to_s } ])
    assert_instance_of Product, args.first

    other_record = SolidCache::Entry.new(key: "x", value: "x", key_hash: 1, byte_size: 1)
    tampered_gid = product.to_global_id.to_s.sub("Product", "SolidCache%3A%3AEntry")
    begin
      tampered = ActiveJob::Arguments.deserialize([ { "_aj_globalid" => tampered_gid } ]).first
      # If it resolved at all, the type is attacker-chosen, not the job's declared type.
      refute_instance_of Product, tampered if tampered
    rescue URI::GID::MissingModelIdError, ActiveJob::DeserializationError
      nil # refused outright - also an acceptable outcome, not a regression
    end
  end

  test "job arguments: hostile strings and hashes are inert data or are refused, never loaded" do
    payloads = [
      Marshal.dump(Fuzz::Marker.new),
      "\x04\x08",
      "--- !ruby/object:Fuzz::Marker {}",
      { "_aj_serialized" => "Kernel" },
      { "_aj_serialized" => "Nope::Missing" }
    ]
    payloads.each do |payload|
      Fuzz::Marker.loaded = false
      begin
        result = ActiveJob::Arguments.deserialize([ payload ])
        assert_equal payload, result.first if payload.is_a?(String)
      rescue ActiveJob::DeserializationError, ArgumentError
        nil # refused - fine
      end
      refute Fuzz::Marker.loaded, "argument deserialization loaded an object for #{payload.inspect}"
    end
  end
end
