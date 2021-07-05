# frozen_string_literal: true

module TwelvedataRuby
  class Error < StandardError
    DEFAULT_MSGS = {
      "TwelvedataRuby::EndpointInvalidPathName" => "Invalid endpoint path name",
      "TwelvedataRuby::EndpointExtraParameters" => "Extra parameters found",
      "TwelvedataRuby::EndpointMissingRequiredParameters" => "Missing required parameters",
      "TwelvedataRuby::ResponseError" => "Encountered an error from the response"
    }.freeze

    attr_reader :attrs, :message

    def initialize(attrs: nil, message: nil)
      @attrs = attrs
      @message = format((message || DEFAULT_MSGS[self.class.name]) + ": %s", @attrs)
      super(@message)
    end
  end

  class EndpointInvalidPathName < Error; end

  class EndpointInvalidParameters < Error; end

  class EndpointMissingRequiredParameters < Error; end

  class ResponseError < Error
    ERROR_CODES_MAP = {
      400 => "BadRequestResponseError",
      401 => "UnauthorizedResponseError",
      403 => "ForbiddenResponseError",
      404 => "NotFoundResponseError",
      414 => "ParameterTooLongResponseError",
      429 => "TooManyRequestsResponseError",
      500 => "InternalServerResponseError"
    }.freeze

    attr_reader :json, :code

    def initialize(attrs: nil, message: nil, json: {}, code: nil)
      @json = json
      @code = code || @json[:code]
      @attrs = @code
      super(attrs: code, message: "#{@json[:message] || message}. Error code is")
    end
  end

  class BadRequestResponseError < ResponseError; end

  class UnauthorizedResponseError < ResponseError; end

  class ForbiddenResponseError < ResponseError; end

  class NotFoundResponseError < ResponseError; end

  class ParameterTooLongResponseError < ResponseError; end

  class TooManyRequestsResponseError < ResponseError; end

  class InternalServerResponseErro < ResponseError; end
end
