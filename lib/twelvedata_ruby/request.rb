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
    attr_accessor :client

    def initialize(endpoint: nil, endpoint_name: nil, params: nil, connect_timeout: nil)
      self.endpoint = endpoint || Endpoint.new(endpoint_name, params)
      @connect_timeout = connect_timeout
    end
    def_delegator :endpoint, :path_name

    def fetch
      return_nil_unless_valid { (client || Client.new(request: self))&.fetch }
    end

    def filename
      params[:filename]
    end

    def format
      params[:format] || DEFAULT_FORMAT
    end

    def format_mime_type
      FORMAT_MIME_TYPES[format]
    end

    def headers
      {headers: self.class.accept_header}
    end

    def http_verb
      return_nil_unless_valid { endpoint.definition[:http_verb] || DEFAULT_HTTP_VERB }
    end

    def options
      headers.merge(timeout)
    end

    def params
      {params: endpoint.params}
    end

    def url
      return_nil_unless_valid { "#{BASE_URL}/#{path_name}" }
    end

    def timeout
      connect_timeout ? {timeout: {connect_timeout: connect_timeout}} : {}
    end

    def to_h
      return_nil_unless_valid { {http_verb: http_verb, url: url}.merge(params) }
    end

    def to_a
      return_nil_unless_valid { [http_verb, url, params] }
    end

    def valid?
      endpoint&.valid?
    end

    private

    attr_writer :endpoint

    def skip_block_unless(truthy_val, return_this=nil, &block)
      truthy_val ? block.call : return_this
    end

    def return_nil_unless_valid(&block)
      skip_block_unless(valid?) { block.call }
    end
  end
end
