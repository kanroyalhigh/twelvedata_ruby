# frozen_string_literal: true

require_relative "twelvedata_ruby/utils"
require_relative "twelvedata_ruby/error"
require_relative "twelvedata_ruby/endpoint"
require_relative "twelvedata_ruby/request"
require_relative "twelvedata_ruby/response"
require_relative "twelvedata_ruby/client"
module TwelvedataRuby
  VERSION = "0.1.0"

  def self.client(**options)
    client = Client.instance
    client.options = options
    client
  end
end
