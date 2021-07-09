# frozen_string_literal: true

require "forwardable"
module TwelvedataRuby
  class Request
    extend Forwardable

    DEFAULT_HTTP_VERB = :get
    FORMAT_MIME_TYPES = {json: "application/json", csv: "text/csv"}.freeze
    VALID_FORMATS = FORMAT_MIME_TYPES.freeze
    DEFAULT_FORMAT = :json

    class << self
      def valid_formats
        @valid_formats ||= FORMAT_MIME_TYPES.keys
      end

      def accept_header
        @accept_header ||= {"Accept" => FORMAT_MIME_TYPES.values.join(",")}
      end
    end

    attr_accessor :endpoint

    def initialize(**options)
      self.endpoint = Endpoint.new(options[:endpoint_name], **(options[:endpoint_params] || {}))
    end
    def_delegators :endpoint, :name, :valid?, :query_params

    def client
      TwelvedataRuby.client
    end

    def fetch
      return_nil_unless_valid { client.fetch(self) }
    end

    def filename
      query_params[:filename]
    end

    def format
      query_params[:format] || DEFAULT_FORMAT
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
      {params: {apikey: client.apikey}.merge(endpoint.query_params)}
    end

    def relative_url
      return_nil_unless_valid { name.to_s }
    end

    def to_h
      return_nil_unless_valid { {http_verb: http_verb, relative_url: relative_url}.merge(params) }
    end

    def to_a
      return_nil_unless_valid { [http_verb, relative_url, params] }
    end
    alias build to_a

    private

    def return_nil_unless_valid(&block)
      Utils.return_nil_unless_true(valid?) { block.call }
    end
  end
end
