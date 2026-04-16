# frozen_string_literal: true

namespace :openapi_ruby do
  desc "Generate OpenAPI spec files from test definitions and components"
  task generate: :environment do
    require "openapi_ruby"
    OpenapiRuby::Generator::SchemaWriter.generate_all!
  end
end
