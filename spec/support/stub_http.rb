# frozen_string_literal: true

module TwelvedataRuby
  module StubHttp
    def mock_request(request)
      stub_http_request(request.http_verb, request.full_url)
    end

    def stub_http_fetch(request, **opts)
      # (a[0].downcase + a[1,a.length-1]).gsub(/([A-Z])/) { |s| '_' + s.downcase }
      err_klass = TwelvedataRuby::ResponseError::ERROR_CODES_MAP[opts[:error_code]]
      fixture_name = if err_klass
        (err_klass[0].downcase + err_klass[1, err_klass.length-1]).gsub(/([A-Z])/) { |s| '_' + s.downcase }
      else
        request.name
      end
      fixture_ext = request.format
      mock_request(request)
        .and_return(
          status: opts[:http_status] || 200,
          body: load_fixture(fixture_name, fixture_ext),
          headers: {
            "Content-Type" => request.format_mime_type
          }.merge(request.filename ? {"Content-Disposition" => "attachment; filename=\"#{request.filename}\""} : {})
        )
    end
  end
end
