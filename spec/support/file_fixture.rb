# frozen_string_literal: true

module TwelvedataRuby
  module FileFixture
    def load_fixture(req_endpoint_name, response_format=:json)
      File.read(File.join(File.expand_path("..", __dir__), "fixtures", "#{req_endpoint_name}.#{response_format}"))
    end
  end
end
