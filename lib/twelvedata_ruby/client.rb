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
        requests.map(&:to_a)
      end
    end

    attr_accessor :connect_timeout
    attr_reader :api_key, :endpoint, :request, :response

    def initialize(options={})
      self.request = options[:request]
      self.endpoint = request&.endpoint ||
                      options[:endpoint] ||
                      (options[:endpoint_name] ? Endpoint(options[:endpoint_name], options[:params]) : nil)
      self.api_key = options[:api_key] || ENV.fetch(API_KEY_ENV_NAME)
      self.connect_timeout = options[:connect_timeout] || CONNECT_TIMEOUT
    end

    def method_missing(endpoint_name, **params, &_block)
      self.endpoint ||= Endpoint.new(endpoint_name, params.merge(api_key: api_key))
      if endpoint.valid?
        self.request ||= Request.new(endpoint: endpoint, connect_timeout: connect_timeout)
        return request
      end
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
