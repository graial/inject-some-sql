# A HARMLESS probe object. If anything instantiates or dispatches to it while
# handling attacker-chosen bytes, `loaded` flips. It contains no gadget.
module Fuzz
  class Marker
    class << self
      attr_accessor :loaded

      # Class-level entry points some loaders call on an attacker-named constant.
      def deserialize(*) = (self.loaded = true; nil)
      def find(*) = (self.loaded = true; nil)
      def unscoped(*) = (self.loaded = true; yield if block_given?)
      def load(*) = (self.loaded = true; nil)
      def json_create(*) = (self.loaded = true; nil)
    end

    def marshal_dump = "marker"
    def marshal_load(_) = (self.class.loaded = true)
    def init_with(_) = (self.class.loaded = true) # YAML (Psych) revival
  end
end
