# frozen_string_literal: true

# require "webmock/rspec"
# require "httpx/adapters/webmock"

describe TwelvedataRuby::Client do
  describe "class constants" do
    it "CONNECT_TIMEOUT is equal to 120" do
      expect(described_class::CONNECT_TIMEOUT).to eq(120)
    end

    it "APIKEY_ENV_NAME is equal to TWELVEDATA_API_KEY" do
      expect(described_class::APIKEY_ENV_NAME).to eq("TWELVEDATA_API_KEY")
    end

    it "BASE_URL is equal to https://api.twelvedata.com" do
      expect(described_class::BASE_URL).to eq("https://api.twelvedata.com")
    end
  end

  describe "class methods" do
    describe ".request" do
      it "can be used by a single request object to fire up a single request to the api"
      it "or can be used with an array of request objects send  multiple request calls in one go"
    end

    it ".build_requests returns an array of the built valid requests for HTTPX" do
      req1 = TwelvedataRuby::Request.new(:api_usage)
      req2 = TwelvedataRuby::Request.new(:quote, symbol: "IBM")
      expect(described_class.build_requests([req1, req2])).to eq([req1.build, req2.build])
    end

    it ".origin returns a Hash instance with `:origin` key and value equals the BASE_URL" do
      expect(described_class.origin).to eq({origin: described_class::BASE_URL})
    end

    it ".timeout a Hash instance with the Client.instance.connect_timeout" do
      expect(described_class.timeout)
        .to eq({timeout: {connect_timeout: TwelvedataRuby::Client.instance.connect_timeout}})
    end

    it ".options a Hash instance from merged .origin and .timeout class methods" do
      expect(described_class.options).to eq(described_class.origin.merge(described_class.timeout))
    end
  end

  describe "instance" do
    let(:endpoint_name) { :quote }
    subject { TwelvedataRuby::Client.instance }

    it "is exactly the same singleton instance object with TwelvedataRuby.client" do
      is_expected.to be_eql(TwelvedataRuby.client)
    end

    it "#apikey and #connect_timeout can be assigned with new values" do
      new_apikey = "new-apikey"
      new_connect_timeout = 200
      expect(subject.apikey).to_not eq(new_apikey)
      expect(subject.connect_timeout).to_not eq(new_connect_timeout)
      subject.apikey = new_apikey
      subject.connect_timeout = new_connect_timeout
      expect(subject.apikey).to eq(new_apikey)
      expect(subject.connect_timeout).to eq(new_connect_timeout)
    end

    context "valid" do
      let(:valid_endpoint_name) { endpoint_name }
      let(:valid_query_params) { {symbol: "IBM"} }

      it "dynamically defines a method if passed name in #respond_to? is a valid endpoint name" do
        expect(TwelvedataRuby::Endpoint.valid_name?(:api_usage)).to eq(true)
        expect { subject.respond_to?(:api_usage) }
          .to change { subject.public_methods.include?(:api_usage) }.from(false).to(true)
      end

      it "defines and fetches automatically a called instance method if name is based on a valid endpoint name" do
        expect(subject.public_methods.include?(valid_endpoint_name)).to eq(false)
        # response = subject.send(valid_endpoint_name, **valid_query_params)
      end
    end

    context "invalid" do
      let(:invalid_params) { {} }
      let(:fetched_request) { subject.send(endpoint_name, **invalid_params) }

      it "when invalid endpoint name called as an instance method, a NoMethodError error will be raised" do
        expect { subject.invalid_endoint_name }.to raise_error(NoMethodError)
      end

      it "if only the endpoint query params is invalid, instance method still be dynamically defined based on name" do
        expect(TwelvedataRuby::Endpoint.valid_name?(endpoint_name)).to eq(true)
        expect(TwelvedataRuby::Endpoint.valid_params?(endpoint_name, **invalid_params)).to eq(false)
        expect { fetched_request }
          .to change { subject.public_methods.include?(endpoint_name) }.from(false).to(true)
      end

      it "with invalid endpoint query params, the request will not be fired" do
        expect(fetched_request).to_not be_an_instance_of(TwelvedataRuby::Response)
        expect(fetched_request).to be_an_instance_of(Hash)
        expect(fetched_request).to have_key(:errors)
      end

      it "with missing required parameters, fetched request will have EndpointRequiredParametersError error instance" do
        expect(fetched_request[:errors][:required_parameters])
          .to be_an_instance_of(TwelvedataRuby::EndpointRequiredParametersError)
      end

      it "with invalid parameters keys, fetched request will have EndpointParametersKeysError error instance" do
        invalid_params.merge!(symbol: "IBM", invalid_param: "yo")
        expect(fetched_request[:errors][:parameters_keys])
          .to be_an_instance_of(TwelvedataRuby::EndpointParametersKeysError)
      end
    end
  end
end
