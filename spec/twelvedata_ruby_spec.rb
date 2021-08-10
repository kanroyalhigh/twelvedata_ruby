# frozen_string_literal: true

describe TwelvedataRuby do
  it "has 0.2.1 version number" do
    expect(described_class::VERSION).to eq("0.2.2")
  end

  describe ".client" do
    subject { described_class.client }
    it "is equal to the singleton Client instance" do
      is_expected.to be_eql(described_class::Client.instance)
    end

    it "#apikey, #options, and #connect_timeout will be always equal to Client.instance's" do
      expect(subject.apikey).to eq(described_class::Endpoint.default_apikey_params[:apikey])
      expect(subject.connect_timeout).to eq(described_class::Client.instance.connect_timeout)
      expect(subject.options).to eq(described_class::Client.instance.options)
    end

    it "on subsequent calls with method parameters, #options, #apikey, and #connect_timeout will be overriten" do
      old_options = subject.options
      old_apikey = subject.apikey
      old_connect_timeout = subject.connect_timeout
      new_options = {apikey: old_apikey + "something", connect_timeout: old_connect_timeout + 60}
      client = described_class.client(**new_options)
      expect(subject).to be_eql(client)
      expect(subject.options).to eq(client.options)
      expect(old_options).to_not eq(client.options)
      expect(old_apikey).to_not eq(client.apikey)
      expect(old_connect_timeout).to_not eq(client.connect_timeout)
    end

    it "on subsequent calls with NO method parameters #options, #apikey, and #connect_timeout NOT be overwritten" do
      client = described_class.client
      expect(client.options).to_not be_empty
      expect(client.apikey).to_not be_nil
      expect(client.connect_timeout).to_not be_nil
    end
  end
end
