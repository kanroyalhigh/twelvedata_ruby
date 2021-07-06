# frozen_string_literal: true

module TwelvedataRuby
  module FileFixture
    def load_fixture(fixture_file)
      File.read(File.join(File.expand_path("..", __dir__), "fixtures", fixture_file))
    end
  end
end
