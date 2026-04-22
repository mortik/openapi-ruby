# frozen_string_literal: true

module OpenapiRuby
  module Middleware
    class PathMatcher
      def initialize(path_templates)
        @matchers = build_matchers(path_templates)
      end

      def match(request_path)
        @matchers.each do |template, pattern|
          match_data = pattern.match(request_path)
          next unless match_data

          path_params = match_data.named_captures.transform_values { |v| Rack::Utils.unescape(v) }
          return [template, path_params]
        end
        nil
      end

      private

      def build_matchers(templates)
        # Sort templates so that static paths come before parameterized ones.
        # This ensures `/admin_users/me` matches before `/admin_users/{id}`.
        sorted = templates.sort_by { |t| [t.count("{"), t] }

        sorted.map do |template|
          pattern = Regexp.new("\\A" + template.gsub(/\{(\w+)\}/) { "(?<#{::Regexp.last_match(1)}>[^/]+)" } + "\\z")
          [template, pattern]
        end
      end
    end
  end
end
