# frozen_string_literal: true

module OpenapiRails
  module Middleware
    class RequestValidation
      def initialize(app, options = {})
        @app = app
        @resolver = options[:schema_resolver] || SchemaResolver.new(spec_path: options[:spec_path])
        @strict = options.fetch(:strict, OpenapiRails.configuration.strict_mode)
        @coerce = options.fetch(:coerce, OpenapiRails.configuration.coerce_params)
        @error_handler = options[:error_handler] || ErrorHandler.new
        @mode = options.fetch(:mode, OpenapiRails.configuration.request_validation)
      end

      def call(env)
        return @app.call(env) if @mode == :disabled

        request = Rack::Request.new(env)
        result = @resolver.find_operation(request.request_method, request.path_info)

        if result.nil?
          return @strict ? @error_handler.not_found(request.path_info) : @app.call(env)
        end

        operation = result[:operation]
        path_params = result[:path_params]
        parameters = operation.fetch("parameters", [])

        # Coerce params if enabled
        if @coerce
          env["rack.request.query_hash"] = Coercion.coerce_params(
            request.GET, parameters.select { |p| p["in"] == "query" }
          )
        end

        # Store operation info for downstream use
        env["openapi_rails.operation"] = operation
        env["openapi_rails.path_params"] = path_params
        env["openapi_rails.path_template"] = result[:template]

        # Validate request
        errors = validate_request(request, operation, path_params)

        if errors.any?
          return @error_handler.invalid_request(errors) unless @mode == :warn_only

          env["openapi_rails.request_errors"] = errors
          warn "[openapi_rails] Request validation warnings: #{errors.join(", ")}"
        end

        @app.call(env)
      end

      private

      def validate_request(request, operation, path_params)
        errors = []
        parameters = operation.fetch("parameters", [])

        # Validate required parameters
        parameters.each do |param|
          next unless param["required"]

          value = case param["in"]
          when "query" then request.GET[param["name"]]
          when "header" then request.get_header("HTTP_#{param["name"].upcase.tr("-", "_")}")
          when "path" then path_params[param["name"]]
          end

          errors << "Missing required #{param["in"]} parameter: #{param["name"]}" if value.nil?
        end

        # Validate request body
        if operation["requestBody"]
          content_type = request.content_type&.split(";")&.first
          rb = operation["requestBody"]

          if rb["required"] && (request.body.nil? || request.body.read.tap { request.body.rewind }.empty?)
            errors << "Request body is required"
          elsif rb["content"] && content_type
            unless rb["content"].key?(content_type)
              errors << "Unsupported content type: #{content_type}"
            end
          end
        end

        errors
      end
    end
  end
end
