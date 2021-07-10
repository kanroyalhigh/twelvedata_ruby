# frozen_string_literal: true

describe TwelvedataRuby::Endpoint do
  describe "class constants" do
    describe "DEFINITIONS" do
      it "is an instance of Hash and is frozen" do
        expect(described_class::DEFINITIONS).to be_an_instance_of(Hash)
        expect(described_class::DEFINITIONS).to be_frozen
      end

      it "all the values have `:parameters` and `:response` keys" do
        expect(described_class::DEFINITIONS.values).to all(include(:parameters, :response))
      end
    end

    describe "DEFAULT_FORMAT and VALID_FORMATS" do
      it "DEFAULT_FORMAT equals to `:json`" do
        expect(described_class::DEFAULT_FORMAT).to eq(:json)
      end

      it "VALID_FORMATS equals to `[:json :csv]`" do
        expect(described_class::VALID_FORMATS).to eq(%i[json csv])
        expect(described_class::VALID_FORMATS).to be_frozen
      end
    end
  end

  describe "class methods" do
    describe ".definitions" do
      it "returns a Hash instance" do
        expect(described_class.definitions).to be_instance_of(Hash)
      end

      it "the returned Hash instance is based on the #{described_class.name}::DEFINITIONS constant" do
        expect(described_class.definitions.keys).to eq(described_class::DEFINITIONS.keys)
      end
    end

    describe ".default_apikey_params" do
      it "is Hash instance with :apikey and value equals to Client.instance.apikey" do
        expect(described_class.default_apikey_params).to eql({apikey: TwelvedataRuby::Client.instance.apikey})
      end
    end

    describe ".names and .valid_name?" do
      it ".names class method returns all the keys from .definitions" do
        expect(described_class.names).to eq(described_class.definitions.keys)
      end

      it "the returned names of .names class method are all valid names as confirmed from .valid_name? class method" do
        expect(described_class.names.map {|name| described_class.valid_name?(name) }).to all(eq(true))
      end
    end

    describe ".valid_params?" do
      it "should return true when passed with valid query params" do
        expect(described_class.valid_params?(:api_usage, apikey: "ahjasas")).to eq(true)
      end

      it "should return false on an invalid or blank or empty query params" do
        expect(described_class.valid_params?(:quote)).to eq(false)
        expect(described_class.valid_params?(:quote, **{})).to eq(false)
        expect(described_class.valid_params?(:quote, **{invalid: ""})).to eq(false)
      end

      it ".valid? is an alias method" do
        expect(described_class.method(:valid?)).to eq(described_class.method(:valid_params?))
      end
    end
  end

  describe "instance" do
    let(:endpoint_attribs) { {name: :api_usage} }
    let(:default_query_params) { described_class.default_apikey_params }
    subject { described_class.new(endpoint_attribs[:name], **(endpoint_attribs[:query_params] || {})) }

    it "should be initialized" do
      is_expected.to_not be_nil
    end

    it "#name and #query_params should return the correct values" do
      expect(subject.name).to eq(endpoint_attribs[:name])
      expect(subject.query_params).to eq(default_query_params.merge(format: described_class::DEFAULT_FORMAT))
      expect(subject.query_params[:apikey]).to eq(TwelvedataRuby::Client.instance.apikey)
    end

    it "#name automatically converts a given name string into a downcased symbol" do
      subject.name = "api_usage"
      expect(subject.name).to eq(:api_usage)
      subject.name = "Api_USAge"
      expect(subject.name).to eq(:api_usage)
    end

    it "query_params[:format] value will be forced to DEFAULT_FORMAT if given format is not valid" do
      endpoint_attribs.merge!(query_params: {format: :not_valid_format})
      expect(subject.query_params[:format]).to eq(described_class::DEFAULT_FORMAT)
    end

    context "valid instance" do
      let(:definition) { described_class.definitions[subject.name] }

      it "#errors returns an empty hash" do
        errors = subject.errors
        expect(errors).to be_an_instance_of(Hash)
        expect(errors).to be_empty
      end

      it "#query_params_keys returns a valid array of keys" do
        endpoint_attribs.merge!(query_params: {format: :csv})
        expect(subject.query_params_keys).to eq(default_query_params.merge(endpoint_attribs[:query_params]).keys)
      end

      it ":apikey can be overriden from the passed method parameters in #new" do
        endpoint_attribs.merge!(query_params: {apikey: "different-apikey"})
        expect(endpoint_attribs[:apikey]).to_not eq(default_query_params[:apikey])
        expect(subject.query_params[:apikey]).to eq(endpoint_attribs[:query_params][:apikey])
      end

      it "#required_parameters returns a valid array of keys" do
        expect(subject.required_parameters).to eq(definition[:parameters][:required])
      end

      it "#parameters_keys returns a valid array of keys" do
        expect(subject.parameters_keys).to eq(definition[:parameters][:keys])
      end

      it "#valid? returns true" do
        expect(subject).to be_valid
      end
    end

    context "invalid instance" do
      let(:endpoint_attribs) { {} }
      it "when name is nil and query_params is nil" do
        is_expected.to_not be_valid
        is_expected.to_not be_valid_name
        is_expected.to_not be_valid_query_params
        expect(subject.errors[:name]).to be_an_instance_of(TwelvedataRuby::EndpointNameError)
        expect(subject.errors[:required_parameters]).to be_an_instance_of(TwelvedataRuby::EndpointError)
      end

      it "when given an invalid name" do
        subject.name = :invalid
        expect(subject.name).to eq(:invalid)
        is_expected.to_not be_valid
        is_expected.to_not be_valid_name
        is_expected.to_not be_valid_query_params
        expect(subject.errors[:name]).to be_an_instance_of(TwelvedataRuby::EndpointNameError)
        expect(subject.errors[:required_parameters]).to be_an_instance_of(TwelvedataRuby::EndpointError)
      end

      it "when given a valid name and invalid query params" do
        subject.name = :api_usage
        subject.query_params = {invalid_param_key: ""}
        is_expected.to_not be_valid
        is_expected.to be_valid_name
        is_expected.to_not be_valid_query_params
        expect(subject.errors[:parameters_keys]).to be_instance_of(TwelvedataRuby::EndpointParametersKeysError)
      end

      it "when given a valid name and missing required query parameters" do
        subject.name = :quote
        subject.query_params = {apikey: "apikey"}
        is_expected.to_not be_valid
        is_expected.to be_valid_name
        is_expected.to_not be_valid_query_params
        expect(subject.errors[:required_parameters]).to be_instance_of(TwelvedataRuby::EndpointRequiredParametersError)
      end

      it "can be corrected and become a valid instance" do
        is_expected.to_not be_valid
        subject.name = :quote
        is_expected.to be_valid_name
        is_expected.to_not be_valid_query_params
        subject.query_params = {symbol: "IBM"}
        is_expected.to be_valid_query_params
        is_expected.to be_valid
      end
    end
  end
end
