# frozen_string_literal: true

describe TwelvedataRuby::Response do
  let(:endpoint_options) { {name: :time_series, query_params: {symbol: "IBM", interval: "1day"}} }
  let(:request) { {request: TwelvedataRuby::Request.new(endpoint_options[:name], **endpoint_options[:query_params])} }
  let(:http_response) do
    req = request[:stubbed] || request[:request]
    TwelvedataRuby::Client.request(req, {origin: req.full_url})
  end
  subject { described_class.new(http_response: http_response, request: request) }

  describe "class constants" do
    it "CSV_COL_SEP is equal to `;`" do
      expect(described_class::CSV_COL_SEP).to eq(";")
    end

    it "HTTP_STATUSES" do
      expect(described_class::HTTP_STATUSES).to be_an_instance_of(Hash)
      expect(described_class::HTTP_STATUSES).to be_frozen
      expect(described_class::HTTP_STATUSES.keys).to eq(%i[http_error success])
      expect(described_class::HTTP_STATUSES[:success]).to eq(200..299)
      expect(described_class::HTTP_STATUSES[:http_error]).to eq(400..1_000)
    end

    it "CONTENT_TYPE_HANDLERS" do
      expect(described_class::CONTENT_TYPE_HANDLERS).to be_an_instance_of(Hash)
      expect(described_class::CONTENT_TYPE_HANDLERS).to be_frozen
      expect(described_class::CONTENT_TYPE_HANDLERS.keys).to eq(%i[json csv plain])
      expect(described_class::CONTENT_TYPE_HANDLERS.values).to all(include(:parser, :dumper))
    end
  end

  context "mock http request" do
    before(:each) do |example|
      endpoint_options[:query_params].merge!(example.metadata[:query_params]) if example.metadata[:query_params]
      expect(request[:request]).to be_valid
      stub_http_fetch(request[:request])
    end
    describe "class methods" do
      describe ".resolve" do
        subject { described_class.resolve(http_response, request[:request]) }

        it "can return a #{described_class} instance on a successfull request fetch" do
          is_expected.to be_an_instance_of(described_class)
        end

        it "can return an instance of kind ResponseError with an API error " do
          stub_http_fetch(request[:request], error_code: 401)
          is_expected.to be_an_instance_of(TwelvedataRuby::UnauthorizedResponseError)
        end

        it "can return an instance of kind ResponseError with the response error from the API web server" do
          invalid_page = "invalid-page"
          stubbed_req = OpenStruct.new(
            build: [:get, invalid_page],
            full_url: "#{TwelvedataRuby::Client.origin[:origin]}/#{invalid_page}"
          )
          request.merge!(stubbed: stubbed_req)
          stub_http_fetch(
            request[:request],
            http_status: 404,
            error_code: 404,
            format: :txt,
            full_url: stubbed_req.full_url
          )

          is_expected.to be_an_instance_of(TwelvedataRuby::ResponseError)
          expect(subject.code).to eq(404)
        end
      end

      describe ".resolve_error" do
        let(:error) { HTTPX::NativeResolveError.new(http_response, http_response.uri.host) }
        subject { described_class.resolve_error(OpenStruct.new(error: error), request[:request]) }
        it "can resolve error from the native http client library" do
          is_expected.to be_an_instance_of(TwelvedataRuby::ResponseError)
          expect(subject.code).to eq(error.class.name)
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

      context ":csv", query_params: {format: :csv} do
        let(:parser_klass) { CSV }
        it "response body processing will be be based on :csv" do
          expect(subject.content_type).to eq(:csv)
          expect(subject.body_parser).to eq(:csv_parser)
          expect(subject.parsed_body_dumper).to eq(:csv_dumper)
        end

        it "#parsed_body returns a `CSV::Table` instance" do
          expect(subject.parsed_body).to be_an_instance_of(CSV::Table)
        end

        it "headers' content-deposition default is `12data_{endpoint_name}.csv` if no `:filename` in query params" do
          expect(subject.attachment_filename).to eq("12data_#{request[:request].name}.csv")
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
