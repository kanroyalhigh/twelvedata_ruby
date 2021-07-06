# frozen_string_literal: true

describe TwelvedataRuby::Endpoint do
  describe "class constants" do
    it "has API_KEY_ENV_NAME constant which is the ENV var name of the test api key from TWELVE DATA" do
      expect(described_class::API_KEY_ENV_NAME).not_to be_nil
    end

    describe "`APIKEY_KEY`" do
      it "it holds the Twelve Data API api key request parameter name: `apikey`" do
        expect(described_class::APIKEY_KEY).to eql(:apikey)
      end
    end

    describe "`DEFINITIONS`" do
      it "is a Hash class constant" do
        expect(described_class::DEFINITIONS).to be_an_instance_of(Hash)
      end

      it "has :parameters key to all its values" do
        expect(described_class::DEFINITIONS.values).to all(have_key(:parameters))
      end
    end
  end

  describe "class methods" do
    describe ".definitions" do
      it "returns a Hash instance" do
        expect(described_class.definitions).to be_instance_of(Hash)
      end

      it "is based on the #{described_class.name}::DEFINITIONS Hash constant" do
        expect(described_class.definitions.keys).to eq(described_class::DEFINITIONS.keys)
      end
    end

    describe ".path_names" do
      it "returns all the valid endpoint names" do
        expect(described_class.path_names).to eq(described_class.definitions.keys)
      end

      it "has all valid endpoint names" do
        not_valid_endpoints = described_class.path_names.reject {|p| TwelvedataRuby::Endpoint.valid_path_name?(p) }
        expect(not_valid_endpoints).to be_empty
      end
    end
  end

  describe "instance" do
    let(:api_usage) { :api_usage }
    let(:api_key) { "api-key" }
    let(:valid_endpoint) { described_class.new(api_usage, apikey: api_key) }
    let(:invalid_endpoint) { described_class.new(:invalid_endpoint_name, api_key: api_key) }
    let(:invalid_quote_endpoint) { described_class.new(:quote, api_key: api_key) }
    let(:valid_quote_endpoint) { described_class.new(:quote, apikey: api_key, symbol: "IBM") }

    it "has instance attribute readers: `#path_name`, `#params`. `#params_keys` is one of the instance methods" do
      expect(valid_endpoint.path_name).to_not be eq(api_usage)
      expect(valid_endpoint.params).to be_an_instance_of(Hash)
      expect(valid_endpoint.params_keys).to be_an_instance_of(Array)

      expect(invalid_endpoint.path_name).to_not be eq(:invalid_endpoint_name)
      expect(invalid_endpoint.params).to be_an_instance_of(Hash)
      expect(invalid_endpoint.params_keys).to be_an_instance_of(Array)
    end

    describe "#initialize" do
      it "`name` param is case-insensitive, can be a String or Symbol, and will be transformed into downcased symbol" do
        expect(described_class.new("api_usage").path_name).to eql(:api_usage)
        expect(described_class.new("ApI_UsaGe").path_name).to eql(:api_usage)
        expect(described_class.new(:ApI_UsaGe).path_name).to eql(:api_usage)
      end

      it "will removed `nil` values from `parameters` method param" do
        endpoint_params = described_class.new(:quote, {symbol: nil, api_key: "api-key"}).params
        expect(endpoint_params).to_not have_key(:symbol)
        expect(endpoint_params).to have_key(:apikey)
      end
    end

    describe "valid/no errors  instance" do
      it "should return true in `#valid?`" do
        expect(valid_endpoint.valid?).to be true
        expect(valid_quote_endpoint.valid?).to be true
      end

      it "should return a Hash instance in `#definition` and `#parameter_keys_definition`" do
        expect(valid_endpoint.definition).to be_an_instance_of(Hash)
        expect(valid_endpoint.parameter_keys_definition).to be_an_instance_of(Array)
      end

      it "has empty array returned in `#errors`" do
        expect(valid_endpoint.errors).to be_empty
        expect(valid_quote_endpoint.errors).to be_empty
      end

      it "has required parameters for all endpoints as apikey parameter is needed to them all" do
        expect(valid_endpoint.required_parameter_keys).to_not be_empty
        expect(valid_quote_endpoint.required_parameter_keys).to_not be_empty
      end
    end

    describe "invalid/erroneous instance" do
      it "will return nil in `#definition` and `#parameter_keys_definition` instance methods" do
        expect(invalid_endpoint.definition).to be_nil
        expect(invalid_endpoint.parameter_keys_definition).to be_nil
      end

      it "`#valid?` will return false  and `Twelvedata::EndpointInvalidPathName` is one of the `#errors`" do
        expect(invalid_endpoint.valid?).to be false
        expect(invalid_endpoint.errors).to include(TwelvedataRuby::EndpointInvalidPathName)
      end

      it "will make sure the required parameters should have values" do
        expect(invalid_quote_endpoint.required_parameter_keys).to include(:symbol)
        expect(invalid_quote_endpoint.params[:symbol]).to be_nil
        expect(invalid_quote_endpoint.errors).to include(TwelvedataRuby::EndpointMissingRequiredParameters)
      end
    end
  end
end
