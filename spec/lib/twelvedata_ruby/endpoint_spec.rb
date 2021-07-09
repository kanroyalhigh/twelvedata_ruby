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
        expect(described_class.valid_params?(:api_usage)).to eq(false)
        expect(described_class.valid_params?(:api_usage, **{})).to eq(false)
        expect(described_class.valid_params?(:api_usage, **{invalid: ""})).to eq(false)
      end

      it ".valid? is an alias method" do
        expect(described_class.method(:valid?)).to eq(described_class.method(:valid_params?))
      end
    end
  end

  describe "instance" do
    let(:endpoint_attribs) { {name: :api_usage, query_params: {apikey: "apikey"}} }
    subject { described_class.new(endpoint_attribs[:name], **(endpoint_attribs[:query_params] || {})) }

    it "should be initialized" do
      is_expected.to_not be_nil
    end

    it "#name and #query_params should return the correct values" do
      expect(subject.name).to eq(endpoint_attribs[:name])
      expect(subject.query_params).to eq(endpoint_attribs[:query_params])
    end

    it "#name automatically converts a given name string into a downcased symbol" do
      subject.name = "api_usage"
      expect(subject.name).to eq(:api_usage)
      subject.name = "Api_USAge"
      expect(subject.name).to eq(:api_usage)
    end

    context "valid instance" do
      let(:definition) { described_class.definitions[subject.name] }

      it "#errors returns an empty hash" do
        errors = subject.errors
        expect(errors).to be_an_instance_of(Hash)
        expect(errors).to be_empty
      end

      it "#query_params_keys returns a valid array of keys" do
        expect(subject.query_params_keys).to eq(endpoint_attribs[:query_params].keys)
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
        subject.name = :api_usage
        is_expected.to be_valid_name
        is_expected.to_not be_valid_query_params
        subject.query_params = {apikey: "apikey"}
        is_expected.to be_valid_query_params
        is_expected.to be_valid
      end
    end
  end
end
