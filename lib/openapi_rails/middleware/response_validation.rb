# frozen_string_literal: true

module OpenapiRails
  module Middleware
    class ResponseValidation
      def initialize(app, options = {})
        @app = app
        @resolver = options[:schema_resolver] || SchemaResolver.new(spec_path: options[:spec_path])
        @error_handler = options[:error_handler] || ErrorHandler.new
        @mode = options.fetch(:mode, OpenapiRails.configuration.response_validation)
        @validate_success_only = options.fetch(:validate_success_only, true)
      end

      def call(env)
        return @app.call(env) if @mode == :disabled

        status, headers, body = @app.call(env)

        # Skip validation for certain status codes
        return [status, headers, body] if skip_validation?(status)

        operation = env["openapi_rails.operation"]
        unless operation
          request = Rack::Request.new(env)
          result = @resolver.find_operation(request.request_method, request.path_info)
          operation = result[:operation] if result
        end
        return [status, headers, body] unless operation

        # Find the response spec
        response_spec = operation.dig("responses", status.to_s) ||
          operation.dig("responses", "default")
        return [status, headers, body] unless response_spec

        # Validate the response body
        response_body = read_body(body)
        errors = validate_response(response_spec, response_body, status, headers)

        if errors.any?
          if @mode == :warn_only
            env["openapi_rails.response_errors"] = errors
            warn "[openapi_rails] Response validation warnings: #{errors.join(", ")}"
          else
            return @error_handler.invalid_response(errors)
          end
        end

        [status, headers, body]
      end

      private

      def skip_validation?(status)
        return true if [204, 304].include?(status)
        return true if @validate_success_only && status >= 400

        false
      end

      def read_body(body)
        content = +""
        body.each { |chunk| content << chunk }
        body.rewind if body.respond_to?(:rewind)

        return nil if content.empty?

        JSON.parse(content)
      rescue JSON::ParserError
        content
      end

      def validate_response(response_spec, response_body, _status, _headers)
        errors = []

        content_spec = response_spec.dig("content", "application/json")
        return errors unless content_spec && content_spec["schema"] && response_body

        schema = content_spec["schema"]
        begin
          schemer = JSONSchemer.schema(schema)
          validation_errors = schemer.validate(response_body).to_a
          validation_errors.each do |err|
            pointer = err["data_pointer"] || ""
            type = err["type"] || "validation_failed"
            errors << "#{pointer}: #{type}".strip
          end
        rescue => e
          errors << e.message
        end

        errors
      end
    end
  end
end
