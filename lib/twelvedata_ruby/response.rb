# frozen_string_literal: true

require "forwardable"

module TwelvedataRuby
  class Response
    HTTP_STATUSES = {
      http_client: {
        http_error: (400..10000),
        success: (200..299)
      },
      api: {
        400 => :bad_request,
        401 => :unauthorized,
        403 => :forbidden,
        404 => :not_found,
        414 => :parameter_too_long,
        429 => :too_many_requests,
        500 => :internal_server_error
      }
    }.freeze
    CONTENT_TYPE_PARSERS = {
      json: :json_parser,
      csv: :csv_parser,
      plain: :plain_parser
    }.freeze

    class << self
      def resolve(http_response)
        if HTTP_STATUSES[:http_client][:success].member?(http_response.status)
          response = new(http_response: http_response)
          response.error || response
        else
          resolve_error(http_response)
        end
      end

      def resolve_error(http_response)
        error_attribs = if HTTP_STATUSES[:http_client][:http_error].member?(http_response.status)
                          {message: http_response.body.to_s, code: http_response.status}
                        elsif http_response.respond_to?(:error) && http_response.error
                          {message: http_response.error.message, code: http_response.error.class.name}
                        end
        TwelvedataRuby::ResponseError.new(json: error_attribs || {})
      end
    end

    attr_reader :headers, :body, :http_response

    def initialize(http_response:, headers: nil, body: nil)
      self.http_response = http_response
      self.headers = headers || http_response.headers
      self.body = body || http_response.body
    end

    def content_type
      # TODO: use regexp
      @content_type ||= headers["content-type"].split(";").first.split("/").last.to_sym
    end

    def body_parser
      CONTENT_TYPE_PARSERS[content_type]
    end

    def parsed_body
      @parsed_body ||= send(body_parser)
    end

    def json_parser
      JSON.parse(body, symbolize_names: true)
    end

    def plain_parser
      body.to_s
    end

    def error
      klass_name = ResponseError::ERROR_CODES_MAP[parsed_body[:code]]
      TwelvedataRuby.const_get(klass_name).new(json: parsed_body) if klass_name
    end

    private

    attr_writer :headers, :body, :http_response
  end
end
