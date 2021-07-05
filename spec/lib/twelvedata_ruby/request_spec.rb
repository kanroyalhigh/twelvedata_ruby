# frozen_string_literal: true

describe TwelvedataRuby::Request do
  describe "class constants" do
    it "has `BASE_URL` constant and is equal to https://api.twelvedata.com" do
      expect(described_class::BASE_URL).to eql("https://api.twelvedata.com")
    end

    it "has `DEFAULT_HTTP_VERB` constant which is equal to `:get`" do
      expect(described_class::DEFAULT_HTTP_VERB).to eql(:get)
    end

    it "has `DEFAULT_FORMAT` constant which is equal to `:json`" do
      expect(described_class::DEFAULT_FORMAT).to eql(:json)
    end

    it "has `VALID_FORMATS` array constant which contants `:json`, and `:csv` only" do
      expect(described_class::VALID_FORMATS).to eql(%i[json csv])
      expect(described_class::VALID_FORMATS.frozen?).to be true
    end

    it "has `FORMAT_MIME_TYPES` Hash constant for the `VALID_FORMATS`" do
      expect(described_class::FORMAT_MIME_TYPES).to be_an_instance_of(Hash)
      expect(described_class::FORMAT_MIME_TYPES.keys).to eql(described_class::VALID_FORMATS)
      expect(described_class::FORMAT_MIME_TYPES.frozen?).to be true
    end
  end

  describe "class methods" do
    it "`VALID_FORMATS` Array constant will be returned in .valid_formats" do
      expect(described_class.valid_formats).to eq(described_class::VALID_FORMATS)
    end

    it "return a Hash with `'Accept'` key in .accept_header" do
      expect(described_class.accept_header).to have_key("Accept")
      expect(described_class.accept_header["Accept"].split(",")).to eq(described_class::FORMAT_MIME_TYPES.values)
    end
  end
end
