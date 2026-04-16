# frozen_string_literal: true

require "openapi_ruby"
require_relative "adapters/rspec"

OpenapiRuby::Adapters::RSpec.install!
