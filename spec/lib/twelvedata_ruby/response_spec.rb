# frozen_string_literal: true

require "webmock/rspec"
require "httpx/adapters/webmock"

describe TwelvedataRuby::Response do
  describe "class constants" do
    it "CSV_COL_SEP" do
      expect(described_class::CSV_COL_SEP).to eq(";")
    end

    it "HTTP_STATUSES" do
      expect(described_class::HTTP_STATUSES).to be_an_instance_of(Hash)
      expect(described_class::HTTP_STATUSES).to be_frozen
      expect(described_class::HTTP_STATUSES.keys).to eq(%i[http_error success])
      expect(described_class::HTTP_STATUSES[:success]).to eq(200..299)
      expect(described_class::HTTP_STATUSES[:http_error]).to eq(400..1_000)
    end

    it "CONTENT_TYPE_HANDLERS" do
      expect(described_class::CONTENT_TYPE_HANDLERS).to be_an_instance_of(Hash)
      expect(described_class::CONTENT_TYPE_HANDLERS).to be_frozen
      expect(described_class::CONTENT_TYPE_HANDLERS.keys).to eq(%i[json csv plain])
      expect(described_class::CONTENT_TYPE_HANDLERS.values).to all(include(:parser, :dumper))
    end
  end

  describe "class methods" do
    it ".resolve"

    it ".resolve_error"
  end

  describe "instance" do
    describe "initialize" do
    end
  end
end
