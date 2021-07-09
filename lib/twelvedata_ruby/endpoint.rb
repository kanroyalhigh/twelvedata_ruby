# frozen_string_literal: true

module TwelvedataRuby
  class Endpoint
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
        },
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
        parameters: {keys: %i[symbol format], required: %i[symbol]},
        response: {keys: %i[symbol rate timestamp]}
      },
      currency_conversion: {
        parameters: {keys: %i[symbol amount format], required: %i[symbol amount]},
        response: {keys: %i[symbol rate amount timestamp]}
      },
      complex_data: {
        parameters: {
          keys: %i[symbols intervals start_date end_date dp order timezone methods name],
          required: %i[symbols intervals start_date end_date]
        },
        response: {keys: %i[data status]},
        http_verb: :post
      },
      earnings: {
        parameters: {keys: %i[symbol exchange country type period outputsize format], required: %i[symbol]},
        response: {keys: %i[date time eps_estimate eps_actual difference surprise_prc]}
      },
      earnings_calendar: {
        parameters: {keys: %i[format]},
        response: {
          keys: %i[
            symbol
            name
            currency
            exchange
            country
            time
            eps_estimate
            eps_estimate
            eps_actual
            difference
            surprise_prc
          ]
        }
      }
    }.freeze

    class << self
      def definitions
        @definitions ||= DEFINITIONS.transform_values {|v|
          v.merge(
            parameters: {
              keys: v[:parameters][:keys].push(:apikey),
              required: (v[:parameters][:required] || []).push(:apikey)
            }
          )
        }.to_h
      end

      def names
        @names ||= definitions.keys
      end

      def valid_name?(name)
        names.include?(name.to_sym)
      end

      def valid_params?(name, **params)
        new(name, **params).valid?
      end
      alias valid? valid_params?
    end

    attr_reader :name, :query_params

    def initialize(name, **query_params)
      self.name = name
      self.query_params = query_params
    end

    def default_apikey_params
      {apikey: Client.instance.apikey}
    end

    def definition
      @definition ||= self.class.definitions[name]
    end

    def errors
      (@errors || {}).compact
    end

    def name=(name)
      assign_attribute(:name, name.to_s.downcase.to_sym)
    end

    def parameters
      return @parameters if definition.nil? || @parameters

      params = definition[:parameters]
      params.push(:filename) if params.include?(:format) && query_parameters[:format] == :csv
      params
    end

    def parameters_keys
      parameters&.send(:[], :keys)
    end

    def query_params_keys
      query_params.keys
    end

    def query_params=(query_params)
      assign_attribute(:query_params, default_apikey_params.merge(query_params.compact))
    end

    def required_parameters
      parameters&.send(:[], :required)
    end

    def valid?
      valid_name? && valid_query_params?
    end

    def valid_at_attributes?(*attrs)
      errors.values_at(*attrs).compact.empty?
    end

    def valid_name?
      valid_at_attributes?(:name)
    end

    def valid_query_params?
      valid_at_attributes?(:parameters_keys, :required_parameters)
    end

    private

    def assign_attribute(attr_name, value)
      @parameters = nil
      @definition = nil
      instance_variable_set(:"@#{attr_name}", value)
      send(:"validate_#{attr_name}")
      send(attr_name)
    end

    def init_error(attr_name, invalid_values, error_klass = nil)
      error_klass ||= Kernel.const_get("#{self.class.name}#{Utils.camelize(attr_name)}Error")
      error_klass.new(endpoint: self, invalid: invalid_values)
    end

    def update_errors(attrib, invalids, klass=nil)
      @errors = errors.merge(attrib => !invalids.nil? && !invalids.empty? ? init_error(attrib, invalids, klass) : nil)
    end

    def validate_name
      is_valid = self.class.valid_name?(name)
      invalid_name = name.nil? || name.empty? ? "a blank name" : name
      update_errors(:name, is_valid ? nil : invalid_name)
      validate_query_params if is_valid && query_params && !valid_query_params?
    end

    def validate_query_params
      return update_errors(:required_parameters, "Invalid name", EndpointError) unless parameters_keys

      update_errors(:required_parameters, required_parameters.difference(query_params_keys))
      update_errors(:parameters_keys, query_params_keys.difference(parameters_keys))
    end
  end
end
