# frozen_string_literal: true

require "httpx"

module TwelvedataRuby
  class Client
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
      init_with_options_or_defaults(options)
      init_endpoint_request(options[:endpoint_name], options[:params]) if endpoint.nil? && options[:endpoint_name]
    end

    # can be client.api_usage.fetch or client.api_usage; client.fetch
    def method_missing(endpoint_name, **params, &_block)
      init_endpoint_request(endpoint_name, params) || super(endpoint_name, params)
    end

    def fetch
      return nil unless request&.valid?

      self.response = Response.resolve(self.class.request(request))
    end

    def respond_to_missing?(endpoint_name, _include_all=false)
      Endpoint.valid_path_name?(endpoint_name) || super
    end

    private

    attr_writer :api_key, :endpoint, :request, :response

    def init_endpoint_request(name, params)
      self.endpoint = Endpoint.new(name, params || {})
      if endpoint.valid?
        self.request = Request.new(endpoint: endpoint)
        request.client = self
      end
      request&.valid? ? request : nil
    end

    def init_with_options_or_defaults(options)
      self.connect_timeout = options[:connect_timeout] || CONNECT_TIMEOUT
      self.request = options[:request]
      self.endpoint = request&.endpoint || options[:endpoint]
    end
  end
end
