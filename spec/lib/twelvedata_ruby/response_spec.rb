# frozen_string_literal: true

describe TwelvedataRuby::Response do
  let(:endpoint_options) { {name: :time_series, query_params: {symbol: "IBM", interval: "1day"}} }

  let(:request) do |example|
    (example.metadata[:stub_http_opts] || {})[:stub_request] ? stub_request : TwelvedataRuby::Request.new(
      endpoint_options[:name], **endpoint_options[:query_params]
    )
  end

  let(:http_response) { TwelvedataRuby::Client.request(request, {origin: request.full_url}) }
  subject { described_class.new(http_response: http_response, request: request) }
  let(:response_error) { subject.error }

  describe "class constants and .http_status_codes class method" do
    it "CSV_COL_SEP is equal to `;`" do
      expect(described_class::CSV_COL_SEP).to eq(";")
    end

    it "BODY_MAX_BYTESIZE is equal to 16_000" do
      expect(described_class::BODY_MAX_BYTESIZE).to eq(16_000)
    end

    it "HTTP_STATUSES" do
      expect(described_class::HTTP_STATUSES).to be_an_instance_of(Hash)
      expect(described_class::HTTP_STATUSES).to be_frozen
      expect(described_class::HTTP_STATUSES.keys).to eq(%i[http_error success])
      expect(described_class::HTTP_STATUSES[:success]).to eq(200..299)
      expect(described_class::HTTP_STATUSES[:http_error]).to eq(400..600)
    end

    it "CONTENT_TYPE_HANDLERS" do
      expect(described_class::CONTENT_TYPE_HANDLERS).to be_an_instance_of(Hash)
      expect(described_class::CONTENT_TYPE_HANDLERS).to be_frozen
      expect(described_class::CONTENT_TYPE_HANDLERS.keys).to eq(%i[json csv plain])
      expect(described_class::CONTENT_TYPE_HANDLERS.values).to all(include(:parser, :dumper))
    end

    it ".http_status_codes returns a flat array of all the HTTP_STATUSES values" do
      expect(described_class.http_status_codes).to eq(described_class::HTTP_STATUSES.values.map(&:to_a).flatten)
    end
  end

  context "mock http request" do
    before(:each) do |example|
      endpoint_options[:query_params].merge!(example.metadata[:query_params]) if example.metadata[:query_params]
      endpoint_options.merge!(example.metadata[:endpoint_options]) if example.metadata[:endpoint_options]
      stub_http_opts = example.metadata[:stub_http_opts] || {}
      expect(request).to be_valid
      stub_http_fetch(request, **(stub_http_opts[:opts] || {}))
    end
    describe "class methods" do
      describe ".resolve" do
        subject { described_class.resolve(http_response, request) }

        it "returns a #{described_class} instance on a successfull request fetch" do
          is_expected.to be_an_instance_of(described_class)
        end

        it "returns an instance of kind ResponseError with the response error from the API web server",
           {
             stub_http_opts: {
               opts: {
                 http_status: 404,
                 error_klass_name: "PageNotFoundResponseError",
                 format: :plain
               },
               stub_request: true
             }
           } do
             expect(response_error).to be_an_instance_of(TwelvedataRuby::PageNotFoundResponseError)
             expect(subject.status_code).to eq(404)
             expect(subject.http_status_code).to eq(404)
             expect(subject.content_type).to eq(:plain)
           end
      end

      describe ".resolve_error" do
        let(:error) do |example|
          example.metadata[:stub_error] ? HTTPX::NativeResolveError.new(http_response, http_response.uri.host) : nil
        end
        subject { described_class.resolve(OpenStruct.new(error: error, status: error.class.name), request) }

        it "can resolve/returns an instance of kind of an error class from http client library", stub_error: true do
          is_expected.to be_an_instance_of(TwelvedataRuby::ResponseError)
          expect(subject.code).to eq(error.class.name)
        end

        it "resolves an unknown http response error" do
          expect(error).to be_nil
          is_expected.to be_an_instance_of(TwelvedataRuby::ResponseError)
        end
      end
    end

    describe "instance" do
      let(:parsed_file_content) { {} }
      before(:each) { is_expected.to be_an_instance_of(described_class) }
      after(:each) do |ex|
        if ex.metadata[:to_disk_file]
          FileUtils.rm_f(ex.metadata[:to_disk_file])
          expect { subject.to_disk_file(ex.metadata[:to_disk_file]) }
            .to change { File.exist?(ex.metadata[:to_disk_file]) }.from(false).to(true)
          expect { parsed_file_content[:content] = parser_klass.parse(File.read(ex.metadata[:to_disk_file])) }
            .to change { parsed_file_content.empty? }.from(true).to(false)
        end
      end

      it "#error returns a kind of TwelvedataRuby::ResponseError instance with error details from the API",
         {stub_http_opts: {opts: {error_code: 404}}} do
           expect(response_error).to be_an_instance_of(TwelvedataRuby::NotFoundResponseError)
           expect(subject.status_code).to eq(404)
           expect(subject.content_type).to eq(:json)
           expect(subject.http_status_code).to eq(200)
         end

      context ":json content type format" do
        let(:parser_klass) { JSON }
        it "response body processing will be be based on :json" do
          expect(subject.content_type).to eq(:json)
          expect(subject.body_parser).to eq(:json_parser)
          expect(subject.parsed_body_dumper).to eq(:json_dumper)
        end

        it "#parsed_body returns a Hash instance" do
          expect(subject.parsed_body).to be_an_instance_of(Hash)
        end

        it "#attachment_filename is nil" do
          expect(subject.attachment_filename).to be_nil
        end

        it "#to_disk_file dumps/persists the parsed body to a disk file", {to_disk_file: "/tmp/response.json"} do
        end
      end

      context ":csv content type format", query_params: {format: :csv} do
        let(:parser_klass) { CSV }
        it "response body processing will be be based on :csv" do
          expect(subject.content_type).to eq(:csv)
          expect(subject.body_parser).to eq(:csv_parser)
          expect(subject.parsed_body_dumper).to eq(:csv_dumper)
        end

        it "can parse long response body", endpoint_options: {name: :cryptocurrencies, query_params: {format: :csv}} do
          expect(subject.body_bytesize).to be > described_class::BODY_MAX_BYTESIZE
          expect(subject.parsed_body).to be_an_instance_of(CSV::Table)
        end

        it "#parsed_body returns a `CSV::Table` instance" do
          expect(subject.parsed_body).to be_an_instance_of(CSV::Table)
        end

        it "headers' content-deposition default is `12data_{endpoint_name}.csv` if no `:filename` in query params" do
          expect(subject.attachment_filename).to eq("12data_#{request.name}.csv")
        end

        it "headers' content-deposition default can be set by the `:filename` in query params",
           {query_params: {format: :csv, filename: "myresponsefilename.csv"}} do |example|
             expect(subject.attachment_filename).to eq(example.metadata[:query_params][:filename])
           end

        it "#to_disk_file dumps/persists the parsed body to a disk file", {to_disk_file: "/tmp/response.csv"} do
        end
      end
    end
  end
end
