# frozen_string_literal: true

module TwelvedataRuby
  class Endpoint
    APIKEY_KEY = :apikey
    DEFINITIONS = {
      api_usage: {
        parameters: { keys: %i[format] }
      },
      stocks: {
        parameters: {
          keys: %i[symbol exchange country type format]
        }
      },
      forex_pairs: {
        parameters: { keys: %i[symbol currency_base currency_quote format] }
      },
      cryptocurrencies: {
        parameters: { keys: %i[symbol exchange currency_base currency_quote format] },
        response: {}
      },
      etf: {
        parameters: { keys: %i[symbol format] }
      },
      indices: {
        parameters: { keys: %i[symbol country format] }
      },
      exchanges: {
        parameters: { keys: %i[type name code country format] }
      },
      cryptocurrency_exchanges: {
        parameters: { keys: %i[name format] }
      },
      technical_indicators: {
        parameters: { keys: [] },
        response: {
          keys: %i[enable full_name description type overlay parameters output_values tinting]
        }
      },
      symbol_search: {
        parameters: { keys: %i[symbol outputsize], required: %i[symbol] }
      },
      earliest_timestamp: {
        parameters: { keys: %i[symbol interval exchange] }
      },
      time_series: {
        parameters: {
          keys: %i[symbol interval exchange country type outputsize format],
          required: %i[symbol interval]
        }
      },
      quote: {
        parameters: {
          keys: %i[symbol interval exchange country volume_time_period type format],
          required: %i[symbol]
        }
      },
      price: {
        parameters: { keys: %i[symbol exchange country type format], required: %i[symbol] }
      },
      eod: {
        parameters: { keys: %i[symbol exchange country type], required: %i[symbol] }
      },
      exchange_rate: {
        parameters: { keys: %i[symbol format], required: %i[symbol] }
      },
      currency_conversion: {
        parameters: { keys: %i[symbol amount format], required: %i[symbol amount] }
      },
      complex_data: {
        parameters: {
          keys: %i[symbols intervals start_date end_date dp order timezone methods name],
          required: %i[symbols intervals start_date end_date]
        },
        http_verb: :post
      },
      earnings: {
        parameters: { keys: %i[symbol exchange country type period outputsize format], required: %i[symbol] }
      },
      earnings_calendar: {
        parameters: { keys: %i[format] }
      }
    }

    class << self
      def definitions
        @definitions ||= DEFINITIONS.map do |k, v|
          [k, v.merge(parameters: {
                        keys: v[:parameters][:keys].push(APIKEY_KEY),
                        required: (v[:parameters][:required] || []).push(APIKEY_KEY)
                      })]
        end.to_h
      end

      def path_names
        @path_names ||= definitions.keys
      end

      def valid_path_name?(name)
        path_names.include?(name.downcase.to_sym)
      end
    end

    attr_reader :path_name, :params

    def initialize(name, parameters = {})
      @path_name = name.to_s.downcase.to_sym
      parameters = (parameters || {}).compact
      parameters[APIKEY_KEY] = parameters.delete(:api_key) unless parameters[APIKEY_KEY]
      @params = parameters
    end

    def definition
      @definition ||= self.class.definitions[path_name]
    end

    def parameter_keys_definition
      return @parameter_keys_definition if @parameter_keys_definition&.any?
      @parameter_keys_definition = definition[:parameters][:keys]
      @parameter_keys_definition.push(:filename) if params_keys.include?(:format) && params[:format] == :csv
      @parameter_keys_definition
    end

    def required_parameter_keys
      @required_parameter_keys ||= definition[:parameters][:required]
    end

    def params_keys
      @params_keys ||= params.keys
    end

    def valid?
      errors.empty? ? true : false
    end

    def errors
      return @errors if @errors

      @errors = []
      return @errors
             .push(EndpointInvalidPathName.new(attrs: "/#{path_name}")) unless self.class.valid_path_name?(path_name)
      @errors << parameters_keys_error(required_parameter_keys, params_keys, EndpointMissingRequiredParameters)
      @errors << parameters_keys_error(params_keys, parameter_keys_definition, EndpointExtraParameters)
      @errors.compact! || @errors
    end

    private

    def parameters_keys_error(minuend_keys, subtrahend_keys, error_klass)
      diff_keys = minuend_keys - subtrahend_keys
      diff_keys.empty? ? nil : error_klass.new(attrs: diff_keys.join(", "))
    end
  end
end
