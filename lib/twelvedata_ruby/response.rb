# frozen_string_literal: true

require "csv"
module TwelvedataRuby
  class Response
    CSV_COL_SEP = ";"
    HTTP_STATUSES = {http_error: (400..1_000), success: (200..299)}.freeze
    CONTENT_TYPE_HANDLERS = {
      json: {parser: :json_parser, dumper: :json_dumper},
      csv: {parser: :csv_parser, dumper: :csv_dumper},
      plain: {parser: :plain_parser, dumper: :plain_dumper}
    }.freeze

    class << self
      def resolve(http_response)
        if HTTP_STATUSES[:success].member?(http_response.status)
          response = new(http_response: http_response)
          response.error || response
        else
          resolve_error(http_response)
        end
      end

      def resolve_error(http_response)
        error_attribs = if HTTP_STATUSES[:http_error].member?(http_response.status)
                          {message: http_response.body.to_s, code: http_response.status}
                        elsif http_response.respond_to?(:error) && http_response.error
                          {message: http_response.error.message, code: http_response.error.class.name}
                        end
        TwelvedataRuby::ResponseError.new(json: error_attribs || {})
      end
    end

    attr_reader :http_response, :headers, :body

    def initialize(http_response:, headers: nil, body: nil)
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
      # TODO: use regexp
      @content_type ||= headers["content-type"].split(";").first.split("/").last.to_sym
    end

    def csv_parser
      parsed_chunk = nil
      opts = {col_sep: CSV_COL_SEP}
      body.each do |chunk|
        if parsed_chunk
          parsed_chunk.push(CSV.parse(chunk, **opts))
        else
          parsed_chunk = CSV.parse(chunk, **opts.merge(headers: true))
        end
      end
      parsed_chunk
    end

    def csv_dumper
      parsed_body.is_a?(CSV::Table) ? parsed_body.to_csv : nil
    end

    def dumped_parsed_body
      @dumped_parsed_body ||= send(parsed_body_dumper)
    end

    def error
      klass_name = ResponseError::ERROR_CODES_MAP[parsed_body[:code]]
      TwelvedataRuby.const_get(klass_name).new(json: parsed_body) if klass_name
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

    def plain_dumper
      parsed_body.to_s
    end

    def plain_parser
      body.to_s
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

    attr_writer :http_response, :headers, :body
  end
end
