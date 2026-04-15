# frozen_string_literal: true

module OpenapiRails
  module Middleware
    module Coercion
      module_function

      def coerce_value(value, schema)
        return value unless value.is_a?(String) && schema.is_a?(Hash)

        type = schema["type"]
        case type
        when "integer"
          Integer(value)
        when "number"
          Float(value)
        when "boolean"
          coerce_boolean(value)
        else
          value
        end
      rescue ArgumentError, TypeError
        value
      end

      def coerce_params(params, parameters)
        return params unless params.is_a?(Hash) && parameters.is_a?(Array)

        params.each_with_object({}) do |(key, value), result|
          param_spec = parameters.find { |p| p["name"] == key.to_s }
          result[key] = if param_spec && param_spec["schema"]
            coerce_value(value, param_spec["schema"])
          else
            value
          end
        end
      end

      def coerce_boolean(value)
        case value.downcase
        when "true", "1", "yes"
          true
        when "false", "0", "no"
          false
        else
          value
        end
      end
    end
  end
end
