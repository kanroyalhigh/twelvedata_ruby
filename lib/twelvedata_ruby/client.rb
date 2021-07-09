# frozen_string_literal: true

require "httpx"
require "singleton"
module TwelvedataRuby
  class Client
    include Singleton

    APIKEY_ENV_NAME = "TWELVEDATA_API_KEY"
    CONNECT_TIMEOUT = 120
    BASE_URL = "https://api.twelvedata.com"

    class << self
      def request(request_objects, opts={})
        HTTPX.with(options.merge(opts)).request(build_requests(request_objects))
      end

      def build_requests(requests)
        Utils.to_a(requests).map(&:build)
      end

      def origin
        @origin ||= {origin: BASE_URL}
      end

      def timeout
        {timeout: {connect_timeout: instance.connect_timeout}}
      end

      def options
        origin.merge(timeout)
      end
    end

    attr_writer :options

    def apikey
      Utils.empty_to_nil(options[:apikey]) || ENV[APIKEY_ENV_NAME]
    end

    def apikey=(apikey)
      options[:apikey] = apikey
    end

    def connect_timeout
      parse_connect_timeout(options[:connect_timeout])
    end

    def connect_timeout=(connect_timeout)
      parse_connect_timeout(connect_timeout)
    end

    def fetch(request)
      return nil unless request
      request.valid? ? Response.resolve(self.class.request(request)) : {errors: request.errors}
    end

    # can be client.api_usage.fetch or client.api_usage; client.fetch
    def method_missing(endpoint_name, **endpoint_params, &_block)
      try_fetch(endpoint_name, endpoint_params) || super
    end

    def options
      @options || @options = {}
    end

    def respond_to_missing?(endpoint_name, _include_all=false)
      Utils.return_nil_unless_true(Endpoint.valid_name?(endpoint_name)) {
        define_endpoint_method(endpoint_name)
      } || super
    end

    private

    def build_request(endpoint_name, endpoint_params)
      Request.new(endpoint_name, **endpoint_params)
    end

    def try_fetch(endpoint_name, endpoint_params)
      respond_to?(endpoint_name) ? fetch(build_request(endpoint_name, endpoint_params)) : nil
    end

    def define_endpoint_method(endpoint_name)
      self.class.define_method(endpoint_name) do |**qparams|
        fetch(build_request(__method__, qparams))
      end
    end

    def parse_connect_timeout(milliseconds)
      options[:connect_timeout] = Utils.to_d(milliseconds, CONNECT_TIMEOUT)
    end
  end
end
