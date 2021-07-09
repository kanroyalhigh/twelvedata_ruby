# frozen_string_literal: true

module TwelvedataRuby
  module Utils
    def self.demodulize(obj)
      obj.to_s.gsub(/^.+::/, "")
    end

    def self.camelize(str)
      str.to_s.split("_").map(&:capitalize).join
    end

    def self.to_a(obj, separator=",")
      obj.respond_to?(:split) ? split(separator) : self
    end

    def self.call_block_if_truthy(truthy_val, return_this=nil, &block)
      truthy_val ? block.call : return_this
    end

    def self.return_nil_unless_true(is_true, &block)
      call_block_if_truthy(is_true == true) { block.call }
    end
  end
end
