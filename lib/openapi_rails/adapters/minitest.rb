# frozen_string_literal: true

require "openapi_rails"

module OpenapiRails
  module Adapters
    module Minitest
      module DSL
        def self.included(base)
          base.extend ClassMethods
          base.class_attribute :_openapi_contexts, default: []
          base.class_attribute :_openapi_spec_name, default: nil
        end

        module ClassMethods
          def openapi_spec(name)
            self._openapi_spec_name = name.to_sym
          end

          def api_path(template, &block)
            context = OpenapiRails::DSL::Context.new(template, spec_name: _openapi_spec_name)
            context.instance_eval(&block) if block
            self._openapi_contexts = _openapi_contexts + [context]
            OpenapiRails::DSL::MetadataStore.register(context)
            context
          end
        end

        def test_response(method, expected_status, params: {}, headers: {}, body: nil, path_params: {}, &block)
          context = find_context_for_method(method)
          raise OpenapiRails::Error, "No api_path defined for #{method.upcase} in #{self.class}" unless context

          operation = context.operations[method.to_s]
          raise OpenapiRails::Error, "No #{method.upcase} operation defined" unless operation

          response_ctx = operation.responses[expected_status.to_s]
          raise OpenapiRails::Error, "No response #{expected_status} defined for #{method.upcase}" unless response_ctx

          # Build the request path
          path = expand_path(context.path_template, params.merge(path_params))

          # Execute the request
          request_params = body || params.reject { |k, _| path_param_names(context).include?(k.to_s) }
          request_headers = headers.dup

          if body.is_a?(Hash)
            request_params = body.to_json
            request_headers["Content-Type"] ||= "application/json"
          end

          send_args = {params: request_params}
          send_args[:headers] = request_headers if request_headers.any?

          send(method, path, **send_args)

          # Validate response
          if OpenapiRails.configuration.validate_responses_in_tests
            assert_equal expected_status, response.status,
              "Expected status #{expected_status}, got #{response.status}"

            if response_ctx.schema_definition
              validator = Testing::ResponseValidator.new
              body_data = parse_response_body
              errors = validator.validate(
                response_body: body_data,
                status_code: response.status,
                response_context: response_ctx
              )
              assert errors.empty?, "Response validation failed:\n#{errors.join("\n")}"
            end
          end

          # Execute additional assertions
          instance_eval(&block) if block
        end

        def parsed_body
          parse_response_body
        end

        private

        def find_context_for_method(method)
          self.class._openapi_contexts.find { |ctx| ctx.operations.key?(method.to_s) }
        end

        def expand_path(template, params)
          template.gsub(/\{(\w+)\}/) do
            name = ::Regexp.last_match(1)
            value = params[name.to_sym] || params[name.to_s]
            value || "{#{name}}"
          end
        end

        def path_param_names(context)
          context.path_parameters.map { |p| p["name"] }
        end

        def parse_response_body
          return nil if response.body.empty?

          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end
      end

      def self.install!
        ::Minitest.after_run do
          OpenapiRails::Generator::SpecWriter.generate_all!
        rescue => e
          warn "[openapi_rails] Spec generation failed: #{e.message}"
        end
      end
    end
  end
end
