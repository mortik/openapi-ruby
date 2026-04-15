# frozen_string_literal: true

class Schemas::ValidationErrors
  include OpenapiRails::Components::Base

  schema(
    type: :object,
    required: %w[errors],
    properties: {
      errors: {type: :array, items: {type: :string}}
    }
  )

  skip_key_transformation true
end
