# frozen_string_literal: true

require "openapi_rails"
require_relative "adapters/minitest"

OpenapiRails::Adapters::Minitest.install!
