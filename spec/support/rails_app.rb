# frozen_string_literal: true

# Load the dummy Rails app for specs that need Rails (generators, engine, integration)
ENV["RAILS_ENV"] ||= "test"
require_relative "../dummy/config/environment"

# Set up the in-memory database
ActiveRecord::Schema.verbose = false
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
load File.expand_path("../dummy/db/schema.rb", __dir__)
