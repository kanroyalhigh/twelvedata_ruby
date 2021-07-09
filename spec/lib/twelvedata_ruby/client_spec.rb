# frozen_string_literal: true

# require "webmock/rspec"
# require "httpx/adapters/webmock"

describe TwelvedataRuby::Client do
  describe "class constants" do
    it "CONNECT_TIMEOUT constant which contains an integer value to be used as the default ms connect_timeout" do
      puts "described_class::CONNECT_TIMEOUT: #{described_class::CONNECT_TIMEOUT}"
      expect(described_class::CONNECT_TIMEOUT).to be_an_instance_of(Integer)
    end
  end

  describe "class methods" do
    describe "#request" do
      it "can be used by a single request object to fire up a single request to the api"
      it "or can be used with an array of request objects send  multiple request calls in one go"
    end
  end

  describe "instance" do
    let(:endpoint) { TwelvedataRuby::Endpoint.new(:api_usage) }
    let(:request) { TwelvedataRuby::Request.new(endpoint: endpoint) }
    let(:client) {
      ->(options={}) { TwelvedataRuby::Client.new(options) }
    }
    let(:default_client) { client[{}] }
    describe "#initialize" do
      it "can instantiate with no arguments passed" do
        htpp_client = default_client
        expect(htpp_client.endpoint).to be_nil
        expect(htpp_client.request).to be_nil
      end

      it "can instantiate request object passed in options args" do
        htpp_client = client[{request: request}]
        expect(htpp_client.request).to eq(request)
        expect(htpp_client.endpoint).to eq(request.endpoint)
      end

      it "can instantiate with endpoint object passed in options args" do
        htpp_client = client[{endpoint: endpoint}]
        expect(htpp_client.request).to be_nil
        expect(htpp_client.endpoint).to eq(endpoint)
      end

      it "can instantiate with no request, and endpoint objects but just the endpoint_name, and endpoint params args" do
        http_client = client[{endpoint_name: :api_usage}]
        expect(http_client.endpoint).not_to be_nil
        expect(http_client.request).not_to be_nil
      end

      it "will use a connect_timeout value passed in the options args" do
        http_client = client[{connect_timeout: 200}]
        expect(http_client.connect_timeout).to eq(200)
      end

      it "will use the default `CONNECT_TIMEOUT` if there was no connect_timeout passed in the options args" do
        expect(default_client.connect_timeout).to eq(described_class::CONNECT_TIMEOUT)
      end
    end
  end
end