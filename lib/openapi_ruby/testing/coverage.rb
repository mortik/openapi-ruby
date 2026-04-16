# frozen_string_literal: true

module OpenapiRuby
  module Testing
    class Coverage
      attr_reader :covered, :total

      def initialize(document)
        @document = document
        @covered = Set.new
        @total = extract_all_endpoints
      end

      def record(method, path, status_code)
        key = "#{method.upcase} #{path} #{status_code}"
        @covered.add(key)
      end

      def uncovered
        @total - @covered
      end

      def percentage
        return 100.0 if @total.empty?

        (@covered.size.to_f / @total.size * 100).round(1)
      end

      def report
        {
          total: @total.size,
          covered: @covered.size,
          uncovered: uncovered.size,
          percentage: percentage,
          missing: uncovered.to_a.sort
        }
      end

      def to_json(*_args)
        JSON.pretty_generate(report)
      end

      private

      def extract_all_endpoints
        endpoints = Set.new
        @document.fetch("paths", {}).each do |path, path_item|
          path_item.each do |method, operation|
            next unless %w[get post put patch delete head options trace].include?(method)
            next unless operation.is_a?(Hash)

            operation.fetch("responses", {}).each_key do |status|
              endpoints.add("#{method.upcase} #{path} #{status}")
            end
          end
        end
        endpoints
      end
    end
  end
end
