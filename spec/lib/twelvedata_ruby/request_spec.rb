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

  describe "instance" do
    let(:endpoint) {
      TwelvedataRuby::Endpoint.new(:price, symbol: "IBM", apikey: ENV.fetch("TWELVEDATA_API_KEY"))
    }
    let(:request) {
      lambda {|options={}|
        TwelvedataRuby::Request.new(
          endpoint: options[:endpoint],
          endpoint_name: options[:endpoint_name],
          params: options[:params],
          connect_timeout: options[:connect_timeout]
        )
      }
    }
    describe "#initialize" do
      it "can instantiate with an endpoint instance object" do
        endpoint_instance_request = request[{endpoint: endpoint}]
        expect(endpoint_instance_request.endpoint).to eql(endpoint)
        expect(endpoint_instance_request.path_name).to eql(endpoint.path_name)
        expect(endpoint_instance_request.valid?).to eql(endpoint.valid?)
      end

      it "can instantiate with a new endpoint by passing an endpoint_name, and Hash params" do
        new_endpoint_request = request[{endpoint_name: :quote}]
        expect(new_endpoint_request.endpoint).not_to eq(endpoint)
        expect(new_endpoint_request.path_name).to eq(:quote)
      end

      it "can instantiate with a new value for `connect_timeout` to be 180" do
        request_with_connect_timeout = request[{endpoin: :endpoin, connect_timeout: 180}]
        expect(request_with_connect_timeout.connect_timeout).to eq(180)
        expect(request_with_connect_timeout.timeout[:timeout][:connect_timeout]).to eq(180)
      end
    end

    describe "valid request" do
      let(:valid_request) { request[{endpoint: endpoint}] }

      it "returns a 3 element array in #to_a" do
        expect(valid_request.to_a).to eq([valid_request.http_verb, valid_request.route, valid_request.params])
      end

      it "returns the equivalent Hash in #to_h" do
        expect(valid_request.to_h).to eq(
          {
            http_verb: valid_request.http_verb,
            route: valid_request.route
          }.merge(valid_request.params)
        )
      end

      xit "fetches successfully the data from the api provider" do
        # pending until we can put the webmock in place
        expect(valid_request.fetch).to eq(true)
      end
    end

    describe "invalid request" do
      let(:invalid_request) {
        request[{endpoint_name: endpoint.path_name, params: {}}]
      }
      it "returns false in #valid?" do
        expect(invalid_request.valid?).to eq(false)
      end

      it "will not fetch any data from the api and just returns nil" do
        expect(invalid_request.fetch).to be_nil
      end
    end
  end
end
