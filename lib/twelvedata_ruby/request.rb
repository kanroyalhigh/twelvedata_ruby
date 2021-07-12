# frozen_string_literal: true

require "forwardable"
module TwelvedataRuby
  class Request
    extend Forwardable

    DEFAULT_HTTP_VERB = :get

    attr_reader :endpoint

    def initialize(name, **query_params)
      self.endpoint = Endpoint.new(name, **query_params)
    end
    def_delegators :endpoint, :name, :valid?, :query_params, :errors

    def fetch
      Client.instance.fetch(self)
    end

    def format_mime_type
      MIME_TYPES[query_params[:format]]
    end

    def http_verb
      return_nil_unless_valid { endpoint.definition[:http_verb] || DEFAULT_HTTP_VERB }
    end

    def params
      {params: endpoint.query_params}
    end

    def relative_url
      return_nil_unless_valid { name.to_s }
    end

    def full_url
      return_nil_unless_valid { "#{Client.origin[:origin]}/#{relative_url}" }
    end

    def to_h
      return_nil_unless_valid { {http_verb: http_verb, relative_url: relative_url}.merge(params: params) }
    end

    def to_a
      return_nil_unless_valid { [http_verb, relative_url, params] }
    end
    alias build to_a

    private

    attr_writer :endpoint

    def return_nil_unless_valid(&block)
      Utils.return_nil_unless_true(valid?) { block.call }
    end
  end
end
