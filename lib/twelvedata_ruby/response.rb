# frozen_string_literal: true

require "csv"
module TwelvedataRuby
  class Response
    CSV_COL_SEP = ";"
    BODY_MAX_BYTESIZE = 16_000
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

    attr_reader :http_response, :headers, :body, :body_bytesize, :request

    def initialize(http_response:, request:, headers: nil, body: nil)
      self.http_response = http_response
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

    def csv_parser(io)
      CSV.parse(io, headers: true, col_sep: CSV_COL_SEP)
    end

    def csv_dumper
      parsed_body.is_a?(CSV::Table) ? parsed_body.to_csv(col_sep: CSV_COL_SEP) : nil
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

    def json_parser(io)
      JSON.parse(io, symbolize_names: true)
    end

    def parsed_body
      return @parsed_body if @parsed_body || http_response&.body.nil? || http_response&.body.closed?

      begin
        tmp_file = nil
        if body_bytesize < BODY_MAX_BYTESIZE
          @parsed_body = send(body_parser, http_response.body.to_s)
        else
          tmp_file = Tempfile.new
          http_response.body.copy_to(tmp_file)
          @parsed_body = send(body_parser, IO.read(tmp_file.path))
        end
      ensure
        http_response.body.close
        tmp_file&.close
        tmp_file&.unlink
      end

      @parsed_body
    end
    alias body parsed_body
    alias parse_http_response_body parsed_body

    def parsed_body_dumper
      CONTENT_TYPE_HANDLERS[content_type][:dumper]
    end

    def plain_parser(io=nil)
      io.to_s || http_response.body.to_s
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

    attr_writer :request

    def http_response=(http_resp)
      @http_response = http_resp
      @body_bytesize = http_resp.body.bytesize
      self.headers = http_response.headers
      parse_http_response_body
    end

    def headers=(http_resp_headers)
      @headers = http_response&.headers
    end
  end
end
