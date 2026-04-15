# frozen_string_literal: true

require "spec_helper"
require "rack"
require "rack/test"

RSpec.describe OpenapiRails::Middleware::RequestValidation do
  include Rack::Test::Methods

  let(:inner_app) { ->(_env) { [200, {"content-type" => "application/json"}, ['{"ok":true}']] } }
  let(:document) do
    {
      "openapi" => "3.1.0",
      "info" => {"title" => "Test", "version" => "1.0"},
      "paths" => {
        "/users" => {
          "get" => {
            "parameters" => [
              {"name" => "page", "in" => "query", "required" => true, "schema" => {"type" => "integer"}}
            ],
            "responses" => {"200" => {"description" => "OK"}}
          },
          "post" => {
            "requestBody" => {
              "required" => true,
              "content" => {"application/json" => {"schema" => {"type" => "object"}}}
            },
            "responses" => {"201" => {"description" => "Created"}}
          }
        },
        "/users/{id}" => {
          "get" => {
            "parameters" => [
              {"name" => "id", "in" => "path", "required" => true, "schema" => {"type" => "integer"}}
            ],
            "responses" => {"200" => {"description" => "OK"}}
          }
        }
      }
    }
  end

  let(:resolver) { OpenapiRails::Middleware::SchemaResolver.new(document: document) }

  let(:app) do
    described_class.new(inner_app, schema_resolver: resolver, mode: :enabled, strict: false)
  end

  it "passes valid requests" do
    get "/users?page=1"
    expect(last_response.status).to eq(200)
  end

  it "rejects requests missing required query params" do
    get "/users"
    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body["details"]).to include(/Missing required query parameter: page/)
  end

  it "passes through undocumented paths in non-strict mode" do
    get "/unknown"
    expect(last_response.status).to eq(200)
  end

  context "with strict mode" do
    let(:app) do
      described_class.new(inner_app, schema_resolver: resolver, mode: :enabled, strict: true)
    end

    it "returns 404 for undocumented paths" do
      get "/unknown"
      expect(last_response.status).to eq(404)
    end
  end

  context "with warn_only mode" do
    let(:app) do
      described_class.new(inner_app, schema_resolver: resolver, mode: :warn_only)
    end

    it "passes invalid requests through with warnings" do
      expect { get "/users" }.to output(/Request validation warnings/).to_stderr
      expect(last_response.status).to eq(200)
    end
  end

  context "with disabled mode" do
    let(:app) do
      described_class.new(inner_app, schema_resolver: resolver, mode: :disabled)
    end

    it "skips all validation" do
      get "/users"
      expect(last_response.status).to eq(200)
    end
  end

  it "validates path parameters" do
    get "/users/42"
    expect(last_response.status).to eq(200)
  end

  it "rejects missing required request body" do
    post "/users", "", {"CONTENT_TYPE" => "application/json"}
    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body["details"]).to include(/Request body is required/)
  end
end
