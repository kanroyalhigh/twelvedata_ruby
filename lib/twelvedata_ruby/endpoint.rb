# frozen_string_literal: true

module TwelvedataRuby
  class Endpoint
    APIKEY_KEY = :apikey
    DEFINITIONS = {
      api_usage: {
        parameters: {keys: %i[format]},
        response: {keys: %i[timestamp current_usage plan_limit]}
      },
      stocks: {
        parameters: {keys: %i[symbol exchange country type format]},
        response: {data_keys: %i[symbol name currency exchange country type], collection: :data}
      },
      forex_pairs: {
        parameters: {keys: %i[symbol currency_base currency_quote format]},
        response: {data_keys: %i[symbol currency_group currency_base currency_quote], collection: :data}
      },
      cryptocurrencies: {
        parameters: {keys: %i[symbol exchange currency_base currency_quote format]},
        response: {data_keys: %i[symbol available_exchanges currency_base currency_quote], collection: :data}
      },
      etf: {
        parameters: {keys: %i[symbol format]},
        response: {data_keys: %i[symbol name currency exchange], collection: :data}
      },
      indices: {
        parameters: {keys: %i[symbol country format]},
        response: {data_keys: %i[symbol name country currency], collection: :data}
      },
      exchanges: {
        parameters: {keys: %i[type name code country format]},
        response: {data_keys: %i[name country code timezone], collection: :data}
      },
      cryptocurrency_exchanges: {
        parameters: {keys: %i[name format]},
        response: {data_keys: %i[name], collection: :data}
      },
      technical_indicators: {
        parameters: {keys: []},
        response: {
          keys: %i[enable full_name description type overlay parameters output_values tinting]
        }
      },
      symbol_search: {
        parameters: {keys: %i[symbol outputsize], required: %i[symbol]},
        response: {
          data_keys: %i[symbol instrument_name exchange exchange_timezone instrument_type country],
          collection: :data
        }
      },
      earliest_timestamp: {
        parameters: {keys: %i[symbol interval exchange]},
        response: {keys: %i[datetime unix_time]}
      },
      time_series: {
        parameters: {
          keys: %i[symbol interval exchange country type outputsize format],
          required: %i[symbol interval]
        },
        response: {
          value_keys: %i[datetime open high low close volume],
          collection: :values,
          meta_keys: %i[symbol interval currency exchange_timezone exchange type]
        }
      },
      quote: {
        parameters: {
          keys: %i[symbol interval exchange country volume_time_period type format],
          required: %i[symbol],
          response: {
            keys: %i[
              symbol
              name
              exchange
              currency
              datetime
              open
              high
              low
              close
              volume
              previous_close
              change
              percent_change
              average_volume
              fifty_two_week
            ]
          }
        }
      },
      price: {
        parameters: {keys: %i[symbol exchange country type format], required: %i[symbol]},
        response: {keys: %i[price]}
      },
      eod: {
        parameters: {keys: %i[symbol exchange country type], required: %i[symbol]},
        response: {keys: %i[symbol exchange currency datetime close]}
      },
      exchange_rate: {
        parameters: {keys: %i[symbol format], required: %i[symbol]}
      },
      currency_conversion: {
        parameters: {keys: %i[symbol amount format], required: %i[symbol amount]}
      },
      complex_data: {
        parameters: {
          keys: %i[symbols intervals start_date end_date dp order timezone methods name],
          required: %i[symbols intervals start_date end_date]
        },
        http_verb: :post
      },
      earnings: {
        parameters: {keys: %i[symbol exchange country type period outputsize format], required: %i[symbol]}
      },
      earnings_calendar: {
        parameters: {keys: %i[format]}
      }
    }.freeze

    class << self
      def definitions
        @definitions ||= DEFINITIONS.transform_values {|v|
          v.merge(
            parameters: {
              keys: v[:parameters][:keys].push(APIKEY_KEY),
              required: (v[:parameters][:required] || []).push(APIKEY_KEY)
            }
          )
        }.to_h
      end

      def path_names
        @path_names ||= definitions.keys
      end

      def valid_path_name?(name)
        path_names.include?(name.downcase.to_sym)
      end
    end

    attr_reader :path_name, :params

    def initialize(name, parameters={})
      @path_name = name.to_s.downcase.to_sym
      parameters = (parameters || {}).compact
      parameters[APIKEY_KEY] = parameters.delete(:api_key) unless parameters[APIKEY_KEY]
      @params = parameters.compact
    end

    def definition
      @definition ||= self.class.definitions[path_name]
    end

    def parameter_keys_definition
      return nil unless definition

      return @parameter_keys_definition if @parameter_keys_definition&.any?
      @parameter_keys_definition = definition[:parameters][:keys]
      @parameter_keys_definition.push(:filename) if params_keys.include?(:format) && params[:format] == :csv
      @parameter_keys_definition
    end

    def required_parameter_keys
      return nil unless definition

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
      unless self.class.valid_path_name?(path_name)
        return @errors.push(EndpointInvalidPathName.new(attrs: "/#{path_name}"))
      end

      @errors << parameters_keys_error(required_parameter_keys, params_keys, EndpointMissingRequiredParameters)
      @errors << parameters_keys_error(params_keys, parameter_keys_definition, EndpointInvalidParameters)
      @errors.compact! || @errors
    end

    private

    def parameters_keys_error(minuend_keys, subtrahend_keys, error_klass)
      diff_keys = minuend_keys - subtrahend_keys
      diff_keys.empty? ? nil : error_klass.new(attrs: diff_keys.join(", "))
    end
  end
end
