# frozen_string_literal: true

module TwelvedataRuby
  module StubHttp
    def mock_request(request)
      stub_http_request(request.http_verb, request.full_url)
    end

    def stub_http_fetch(request)
      mock_request(request)
        .and_return(
          status: 200,
          body: load_fixture(request.name, request.format),
          headers: {
            "Content-Type" => request.format_mime_type
          }.merge(request.filename ? {"Content-Disposition" => "attachment; filename=\"#{request.filename}\""} : {})
        )
      Response.resolve(Client.request(request))
    end
  end
end
