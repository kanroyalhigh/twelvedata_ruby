# frozen_string_literal: true

require_relative "lib/twelvedata_ruby"

Gem::Specification.new do |spec|
  spec.name = "twelvedata_ruby"
  spec.version = TwelvedataRuby::VERSION
  spec.authors = ["Kendo Camajalan, KCD"]
  spec.email = ["ken.d.camajalan@pm.me"]
  spec.summary = "A Ruby gem for accessing Twelve Data's stock market APIs"
  spec.description = "A Ruby gem for accessing Twelve Data's stock market APIs."
  spec.homepage = "https://github.com/kanroyalhigh/twelvedata_ruby"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kanroyalhigh/twelvedata_ruby"
  spec.metadata["changelog_uri"] = "https://github.com/kanroyalhigh/twelvedata_ruby/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject {|f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "httpx"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "simplecov"
end
