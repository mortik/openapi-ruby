# frozen_string_literal: true

module OpenapiRails
  module Middleware
    class SchemaResolver
      def initialize(spec_path: nil, document: nil)
        @spec_path = spec_path
        @document = document
        @path_matcher = nil
        @schemer = nil
      end

      def document
        @document ||= load_document
      end

      def schemer
        @schemer ||= JSONSchemer.openapi(document)
      end

      def path_matcher
        @path_matcher ||= PathMatcher.new(document.fetch("paths", {}).keys)
      end

      def find_operation(method, request_path)
        result = path_matcher.match(request_path)
        return nil unless result

        template, path_params = result
        operation = document.dig("paths", template, method.downcase)
        return nil unless operation

        {
          operation: operation,
          template: template,
          path_params: path_params
        }
      end

      private

      def load_document
        raise ConfigurationError, "No spec_path configured for middleware" unless @spec_path

        raw = File.read(@spec_path)
        if @spec_path.end_with?(".yaml", ".yml")
          YAML.safe_load(raw, permitted_classes: [Date, Time])
        else
          JSON.parse(raw)
        end
      end
    end
  end
end
