# frozen_string_literal: true

require "csv"
module TwelvedataRuby
  class Response
    CSV_COL_SEP = ";"
    HTTP_STATUSES = {http_error: (400..600), success: (200..299)}.freeze
    CONTENT_TYPE_HANDLERS = {
      json: {parser: :json_parser, dumper: :json_dumper},
      csv: {parser: :csv_parser, dumper: :csv_dumper},
      plain: {parser: :plain_parser, dumper: :to_s}
    }.freeze

    class << self
      def resolve(http_response, request)
        if http_status_codes.member?(http_response.status)
          new(http_response: http_response, request: request)
        else
          resolve_error(http_response, request)
        end
      end

      def resolve_error(http_response, request)
        error_attribs = if http_response.respond_to?(:error) && http_response.error
                          {message: http_response.error.message, code: http_response.error.class.name}
                        else
                          {message: http_response.body.to_s, code: http_response.status}
                        end
        TwelvedataRuby::ResponseError.new(json: (error_attribs || {}), request: request)
      end

      def http_status_codes
        @http_status_codes ||= HTTP_STATUSES.values.map(&:to_a).flatten
      end
    end

    attr_reader :http_response, :headers, :body, :request

    def initialize(http_response:, request:, headers: nil, body: nil)
      self.http_response = http_response
      self.headers = headers || http_response.headers
      self.body = body || http_response.body
    end

    def attachment_filename
      return nil unless headers["content-disposition"]

      @attachment_filename ||= headers["content-disposition"].split("filename=").last.delete("\"")
    end

    def body_parser
      CONTENT_TYPE_HANDLERS[content_type][:parser]
    end

    def content_type
      @content_type ||= headers["content-type"].match(%r{^.+/([a-z]+).*$})&.send(:[], 1)&.to_sym
    end

    def csv_parser
      chunk_parsed = nil
      opts = {col_sep: CSV_COL_SEP}
      body.each do |chk|
        chunk_parsed = chunk_parsed&.send(:push, CSV.parse(chk, **opts)) || CSV.parse(chk, **opts.merge(headers: true))
      end
      chunk_parsed
    end

    def csv_dumper
      parsed_body.is_a?(CSV::Table) ? parsed_body.to_csv : nil
    end

    def dumped_parsed_body
      @dumped_parsed_body ||=
        parsed_body.respond_to?(parsed_body_dumper) ? parsed_body.send(parsed_body_dumper) : send(parsed_body_dumper)
    end

    def error
      klass_name = ResponseError.error_code_klass(status_code, success_http_status? ? :api : :http)
      return unless klass_name
      TwelvedataRuby.const_get(klass_name)
        .new(json: parsed_body, request: request, code: status_code, message: parsed_body)
    end

    def http_status_code
      http_response&.status
    end

    def json_dumper
      parsed_body.is_a?(Hash) ? JSON.dump(parsed_body) : nil
    end

    def json_parser
      JSON.parse(body, symbolize_names: true)
    end

    def parsed_body
      @parsed_body ||= send(body_parser)
    end

    def parsed_body_dumper
      CONTENT_TYPE_HANDLERS[content_type][:dumper]
    end

    def plain_parser
      body.to_s
    end

    def status_code
      @status_code ||= parsed_body.is_a?(Hash) ? parsed_body[:code] : http_status_code
    end

    def success_http_status?
      @success_http_status ||= HTTP_STATUSES[:success].member?(http_status_code) || false
    end

    def to_disk_file(file_fullpath=attachment_filename)
      return nil unless file_fullpath

      begin
        file = File.open(file_fullpath, "w")
        file.puts dumped_parsed_body
        file
      ensure
        file&.close
      end
    end

    private

    attr_writer :http_response, :headers, :body, :request
  end
end
