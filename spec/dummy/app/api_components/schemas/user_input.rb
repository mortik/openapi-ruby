# frozen_string_literal: true

class Schemas::UserInput
  include OpenapiRails::Components::Base

  schema(
    type: :object,
    required: %w[name email],
    properties: {
      name: {type: :string, minLength: 1},
      email: {type: :string, minLength: 1}
    }
  )

  skip_key_transformation true
end
