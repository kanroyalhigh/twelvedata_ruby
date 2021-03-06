# frozen_string_literal: true

require "simplecov"
SimpleCov.start
require "webmock/rspec"
require "httpx/adapters/webmock"
require "support/file_fixture"
require "twelvedata_ruby"
require "support/stub_http"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  # see: https://relishapp.com/rspec/rspec-core/v/3-0/docs/configuration/global-namespace-dsl
  config.expose_dsl_globally = true

  WebMock.enable!

  config.include TwelvedataRuby::FileFixture
  config.include TwelvedataRuby::StubHttp
end
