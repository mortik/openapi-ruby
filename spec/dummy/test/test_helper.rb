# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "../config/environment"
require "minitest/autorun"
require "openapi_ruby/minitest"

# Set up in-memory database
ActiveRecord::Schema.verbose = false
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
load File.expand_path("../db/schema.rb", __dir__)

# Load components
Dir[File.expand_path("../app/api_components/**/*.rb", __dir__)].each { |f| require f }
