# frozen_string_literal: true

module TwelvedataRuby
  class Error < StandardError
    DEFAULT_MSGS = {
      "EndpointError" => "Endpoint is not valid. %{invalid}",
      "EndpointNameError" => "`%{invalid}` is not a correct endpoint. Valid values are: `%{valid_names}`",
      "EndpointParametersKeysError" => "Invalid parameters found: `%{invalid}`. Valid parameters for `%{name}` "\
        "endpoint are: `%{parameters}`. Please see: `Twelvedata::Endpoint#parameters` for more details",
      "EndpointRequiredParametersError" => "Missing values for required parameters: `%{invalid}`. "\
        "`%{name}` endpoint required parameters are: `%{required}`.",
      "ResponseError" => "Encountered an error from the response"
    }.freeze

    attr_reader :attrs

    def initialize(args={})
      @attrs = args[:attrs] || {}
      super((args[:message] || DEFAULT_MSGS[Utils.demodulize(self.class)]) % @attrs)
    end
  end
  class EndpointError < Error
    def initialize(**args)
      endpoint = args[:endpoint]
      super(
        attrs: {
          name: endpoint.name,
          invalid: args[:invalid],
          valid_names: endpoint.class.names.join(", "),
          parameters: endpoint&.parameters_keys&.send(:join, ", "),
          required: endpoint&.required_parameters&.send(:join, ", ")
        }
      )
    end
  end

  class EndpointNameError < EndpointError; end

  class EndpointParametersKeysError < EndpointError; end

  class EndpointRequiredParametersError < EndpointError; end

  class ResponseError < Error
    ERROR_CODES_MAP = {
      400 => "BadRequestResponseError",
      401 => "UnauthorizedResponseError",
      403 => "ForbiddenResponseError",
      404 => "PageNotFoundResponseError",
      414 => "ParameterTooLongResponseError",
      429 => "TooManyRequestsResponseError",
      500 => "InternalServerResponseError"
    }.freeze

    attr_reader :json, :code, :request

    def initialize(json:, request:, attrs: nil, message: nil, code: nil)
      @json = json
      @code = code || @json[:code]
      @attrs = attrs || {}
      @request = request
      super(attrs: @attrs, message: "#{@json[:message] || message}")
    end
  end

  class BadRequestResponseError < ResponseError; end

  class UnauthorizedResponseError < ResponseError; end

  class ForbiddenResponseError < ResponseError; end

  class PageNotFoundResponseError < ResponseError; end

  class ParameterTooLongResponseError < ResponseError; end

  class TooManyRequestsResponseError < ResponseError; end

  class InternalServerResponseErro < ResponseError; end
end
