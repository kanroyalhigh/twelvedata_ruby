# frozen_string_literal: true

require "forwardable"

module TwelvedataRuby
  class Request
    extend Forwardable

    BASE_URL = "https://api.twelvedata.com"
    DEFAULT_HTTP_VERB = :get
    DEFAULT_FORMAT = :json
    VALID_FORMATS = %i[json csv].freeze
    FORMAT_MIME_TYPES = {json: "application/json", csv: "text/csv"}.freeze

    class << self
      def valid_formats
        @valid_formats ||= FORMAT_MIME_TYPES.keys
      end

      def accept_header
        @accept_header ||= {"Accept" => FORMAT_MIME_TYPES.values.join(",")}
      end
    end

    attr_reader :endpoint, :connect_timeout

    def initialize(endpoint: nil, path_name: nil, params: nil, connect_timeout: nil)
      self.endpoint = endpoint || Endpoint.new(path_name, params)
      @connect_timeout = connect_timeout
    end
    def_delegator :endpoint, :path_name

    def valid?
      endpoint&.valid?
    end

    def format
      params[:format] || DEFAULT_FORMAT
    end

    def filename
      params[:filename]
    end

    def format_mime_type
      FORMAT_MIME_TYPES[format]
    end

    def http_verb
      return nil unless endpoint.valid?

      endpoint.definition[:http_verb] || DEFAULT_HTTP_VERB
    end

    def headers
      {headers: self.class.accept_header}
    end

    def timeout
      connect_timeout ? {timeout: {connect_timeout: connect_timeout}} : {}
    end

    def options
      headers.merge(timeout)
    end

    def route
      "#{BASE_URL}/#{path_name}"
    end

    def params
      {params: endpoint.params}
    end

    def to_h
      {
        http_verb: http_verb,
        route: route
      }.merge(params)
    end

    def to_a
      [http_verb, route, params]
    end

    def fetch
      Client.new(request: self)&.fetch
    end

    private

    attr_writer :endpoint
  end
end
