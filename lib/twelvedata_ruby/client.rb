# frozen_string_literal: true

require "httpx"

module TwelvedataRuby
  class Client
    API_KEY_ENV_NAME = "TWELVEDATA_API_KEY"
    CONNECT_TIMEOUT = 120

    class << self
      def request(request_objects, options={})
        HTTPX.with(options).request(build_requests(request_objects))
      end

      def build_requests(requests)
        requests = [requests] unless requests.is_a?(Array)
        requests.map {|r| r.to_a }
      end
    end

    attr_accessor :connect_timeout
    attr_reader :api_key, :endpoint, :request, :response

    def initialize(endpoint: nil, endpoint_name: nil, params: nil, request: nil, api_key: nil, connect_timeout: nil)
      self.request = request
      self.endpoint = request ? request.endpoint : (endpoint || (endpoint_name ? Endpoint(endpoint_name, params) : nil))
      self.api_key = api_key || ENV.fetch(API_KEY_ENV_NAME)
      self.connect_timeout = connect_timeout || CONNECT_TIMEOUT
    end

    def method_missing(endpoint_name, **params, &_block)
      self.endpoint ||= Endpoint.new(endpoint_name, params.merge(api_key: api_key))
      self.request ||= Request
        .new(endpoint: endpoint, connect_timeout: connect_timeout) and return request if endpoint.valid?

      super(endpoint_name, params)
    end

    def fetch
      return nil unless request&.valid?

      self.response = self.class.request(request)
    end

    def respond_to_missing?(endpoint_name, _include_all=false)
      Endpoint.valid_path_name?(endpoint_name) || super
    end

    private

    attr_writer :api_key, :endpoint, :request, :response
  end
end
