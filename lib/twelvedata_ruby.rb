# frozen_string_literal: true

require_relative "twelvedata_ruby/utils"
require_relative "twelvedata_ruby/error"
require_relative "twelvedata_ruby/endpoint"
require_relative "twelvedata_ruby/request"
require_relative "twelvedata_ruby/response"
require_relative "twelvedata_ruby/client"

# The one module that all the classes and modules of this gem are namespaced

module TwelvedataRuby
  # Holds the current version
  # @return [String] version number
  VERSION = "0.1.0"

  # A convenient and clearer way of getting and overriding default attribute values of the singleton `Client.instance`
  #
  # @param [Hash] options the optional Hash object that may contain values to override the defaults
  # @option options [Symbol, String] :apikey the private key from Twelvedata API key
  # @option options [Integer, String] :connect_timeout milliseconds
  #
  #  @example Passing a nil options
  #    TwelvedataRuby.client
  #
  #  The singleton instance  object returned will use the default values  for its attributes
  #
  #  @example Passing values of `:apikey` and `:connect_timeout`
  #    TwelvedataRuby.client(apikey: "my-twelvedata-apikey", connect_timeout: 3000)
  #
  #  @example or, chain with other Client instance method
  #    TwelvedataRuby.client(apikey: "my-twelvedata-apikey", connect_timeout: 3000).quote(symbol: "IBM")
  #
  #  In the last example, calling `#quote`, a valid API endpoint, an instance method with the same name
  #  was dynamically defined and then fired up an API request to Twelvedata.
  #
  # @return [Client] singleton instance
  def self.client(**options)
    client = Client.instance
    client.options = (client.options || {}).merge(options)
    client
  end
end
