# frozen_string_literal: true

require "httpx"
require "singleton"

module TwelvedataRuby
  # Responsible of the actual communication -- sending a valid request
  #   and receiving the response  -- of the API web server
  class Client
    include Singleton
    # @return [String] the exported shell ENV variable name that holds the apikey
    APIKEY_ENV_NAME = "TWELVEDATA_API_KEY"
    # @return [Integer] CONNECT_TIMEOUT default connection timeout in milliseconds
    CONNECT_TIMEOUT = 120
    # @return [String] valid URI base url string of the API
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

    # @!attribute options
    #   @return [Hash] the options writeonly attribute that may contain values to override the default attribute values.
    #     This attribute writer was automatically called in @see TwelvedataRuby.client(**options).
    # @see TwelvedataRuby.client
    attr_writer :options

    # @return [String] apikey value from the instance options Hash object
    #   but if nill use the value from +ENV[APIKEY_ENV_NAME]+
    def apikey
      Utils.empty_to_nil(options[:apikey]) || ENV[APIKEY_ENV_NAME]
    end

    # The writer method that can be used to pass manually the value of the +apikey+
    # @param [String] +apikey+
    # @return [String] +apikey+ value
    def apikey=(apikey)
      options[:apikey] = apikey
    end

    def connect_timeout
      parse_connect_timeout(options[:connect_timeout])
    end

    def connect_timeout=(connect_timeout)
      parse_connect_timeout(connect_timeout)
    end

    # The actual API fetch that transport the built request object.
    # +Request#valid?+ guards the actual fetch and instead will return a Hash instance of endpoint errors.
    # If +Request#valid?+ returns true, request object will be sent to the API and returned response will
    # will be resolved which may or may not contain a kind of +ResponseError+ instance.
    # @see Response.resolve for more details

    # @param [Request] +request+ built API request object that holds the endpoint payload
    #
    # @return [NilClass] +nil+ if @param +request+ is not truthy
    # @return [Hash] :errors if the request is not valid will hold the  endpoint errors details
    #   @see Endpoint#errors
    # @return [Response] if +request+ is valid and received an actual response from the API server.
    #   The response object's #error may or may not return a kind of ResponseError
    #   @see Response#error
    # @return [ResponseError] if the response received did not come from the API server itself.
    #
    def fetch(request)
      return nil unless request

      request.valid? ? Response.resolve(self.class.request(request), request) : {errors: request.errors}
    end

    # The entry point in dynamically defining instance methods based on the called the valid endpoint names.
    # @param [String] +endpoint_name+ valid API endpoint name to fetch
    # @param [Hash] +endpoint_params+ the optional/required valid query params of the API endpoint.
    #   If +:apikey+ key-value pair is present, the pair will override the +#apikey+ of singleton client instance
    #   If +:format+ key-value pair is present and is a valid parameter key and value can only be +:csv+ or +:json+
    #   If +:filename+ key-value is present and +:format+ is +:csv+, then this is will be added to the payload too.
    #      Otherwise, this will just discarded and will not be part of the payload
    #   If endpoint name and query params used are not valid, EndpointError instances will be returned
    #     actual API fetch will not happen. @see #fetch for the rest of the documentation
    #
    # @todo define all the method signatures of the endpoint methods that will meta-programatically defined at runtime.
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
