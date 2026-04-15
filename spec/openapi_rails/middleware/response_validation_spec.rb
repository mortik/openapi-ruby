# frozen_string_literal: true

require "spec_helper"
require "rack"
require "rack/test"

RSpec.describe OpenapiRails::Middleware::ResponseValidation do
  include Rack::Test::Methods

  let(:document) do
    {
      "openapi" => "3.1.0",
      "info" => {"title" => "Test", "version" => "1.0"},
      "paths" => {
        "/users" => {
          "get" => {
            "responses" => {
              "200" => {
                "description" => "OK",
                "content" => {
                  "application/json" => {
                    "schema" => {
                      "type" => "object",
                      "required" => ["name"],
                      "properties" => {"name" => {"type" => "string"}}
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  let(:resolver) { OpenapiRails::Middleware::SchemaResolver.new(document: document) }

  # We need request validation to set env["openapi_rails.operation"]
  let(:request_middleware) do
    OpenapiRails::Middleware::RequestValidation.new(
      nil, schema_resolver: resolver, mode: :disabled
    )
  end

  context "with valid responses" do
    let(:inner_app) do
      ->(_env) { [200, {"content-type" => "application/json"}, ['{"name":"Jane"}']] }
    end

    let(:app) do
      # Chain: request_validation (sets env) -> response_validation -> inner_app
      req_mw = OpenapiRails::Middleware::RequestValidation.new(inner_app, schema_resolver: resolver, mode: :disabled)
      described_class.new(req_mw, schema_resolver: resolver, mode: :enabled, validate_success_only: false)
    end

    it "passes valid responses" do
      get "/users"
      expect(last_response.status).to eq(200)
    end
  end

  context "with invalid responses" do
    let(:inner_app) do
      ->(_env) { [200, {"content-type" => "application/json"}, ['{"age":30}']] }
    end

    let(:app) do
      req_mw = OpenapiRails::Middleware::RequestValidation.new(inner_app, schema_resolver: resolver, mode: :disabled)
      described_class.new(req_mw, schema_resolver: resolver, mode: :enabled, validate_success_only: false)
    end

    it "returns 500 for invalid response bodies" do
      get "/users"
      expect(last_response.status).to eq(500)
    end
  end

  context "with disabled mode" do
    let(:inner_app) do
      ->(_env) { [200, {"content-type" => "application/json"}, ['{"invalid":true}']] }
    end

    let(:app) do
      req_mw = OpenapiRails::Middleware::RequestValidation.new(inner_app, schema_resolver: resolver, mode: :disabled)
      described_class.new(req_mw, schema_resolver: resolver, mode: :disabled)
    end

    it "skips validation" do
      get "/users"
      expect(last_response.status).to eq(200)
    end
  end

  context "with 204 responses" do
    let(:inner_app) do
      ->(_env) { [204, {}, []] }
    end

    let(:app) do
      req_mw = OpenapiRails::Middleware::RequestValidation.new(inner_app, schema_resolver: resolver, mode: :disabled)
      described_class.new(req_mw, schema_resolver: resolver, mode: :enabled, validate_success_only: false)
    end

    it "skips validation for 204" do
      get "/users"
      expect(last_response.status).to eq(204)
    end
  end
end
