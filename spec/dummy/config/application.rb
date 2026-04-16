# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "active_record/railtie"
require "openapi_ruby"
require "openapi_ruby/engine"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.hosts.clear
    config.secret_key_base = "test_secret_key_base_for_openapi_ruby_dummy"
  end
end
