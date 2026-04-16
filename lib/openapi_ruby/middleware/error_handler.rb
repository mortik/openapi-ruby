# frozen_string_literal: true

module OpenapiRuby
  module Middleware
    class ErrorHandler
      def invalid_request(errors)
        body = {error: "Request validation failed", details: errors}.to_json
        [400, {"content-type" => "application/json"}, [body]]
      end

      def not_found(path)
        body = {error: "Path not found: #{path}"}.to_json
        [404, {"content-type" => "application/json"}, [body]]
      end

      def invalid_response(errors)
        body = {error: "Response validation failed", details: errors}.to_json
        [500, {"content-type" => "application/json"}, [body]]
      end
    end
  end
end
