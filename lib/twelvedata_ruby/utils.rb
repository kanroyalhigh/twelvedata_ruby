# frozen_string_literal: true

module TwelvedataRuby
  module Utils
    def self.demodulize(obj)
      obj.to_s.gsub(/^.+::/, "")
    end

    # Converts a string to integer an all integer or nothing
    def self.to_d(obj, default_value=nil)
      return obj if obj.is_a?(Integer)

      obj.to_s.match(/^\d+$/) {|m| Integer(m[0]) } || default_value
    end

    def self.camelize(str)
      str.to_s.split("_").map(&:capitalize).join
    end

    def self.empty_to_nil(obj)
      !obj.nil? && obj.empty? ? nil : obj
    end

    def self.to_a(objects)
      objects.is_a?(Array) ? objects : [objects]
    end

    def self.call_block_if_truthy(truthy_val, return_this=nil, &block)
      truthy_val ? block.call : return_this
    end

    def self.return_nil_unless_true(is_true, &block)
      call_block_if_truthy(is_true == true) { block.call }
    end
  end
end
