# frozen_string_literal: true

require_relative "application"

Dummy::Application.initialize! unless Dummy::Application.initialized?
