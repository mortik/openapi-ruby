# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rake"
  gem "rspec-rails"
  gem "standard", ">= 1.35.1", require: false
  gem "standard-rspec", require: false
end

group :test do
  gem "minitest"
  gem "rack-test"
  rails_version = ENV.fetch("RAILS_VERSION", nil)
  if rails_version
    gem "rails", "~> #{rails_version}.0"
  else
    gem "rails", ">= 7.0"
  end
  gem "sqlite3"
end
