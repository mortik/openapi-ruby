# frozen_string_literal: true

class Schemas::User
  include OpenapiRails::Components::Base

  schema(
    type: :object,
    required: %w[id name email],
    properties: {
      id: {type: :integer},
      name: {type: :string},
      email: {type: :string},
      createdAt: {type: [:string, :null], format: "date-time"},
      updatedAt: {type: [:string, :null], format: "date-time"}
    }
  )

  skip_key_transformation true
end
