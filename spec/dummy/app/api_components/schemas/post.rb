# frozen_string_literal: true

class Schemas::Post
  include OpenapiRuby::Components::Base

  schema(
    type: :object,
    required: %w[id title user_id],
    properties: {
      id: {type: :integer},
      title: {type: :string},
      body: {type: [:string, :null]},
      user_id: {type: :integer},
      createdAt: {type: [:string, :null], format: "date-time"},
      updatedAt: {type: [:string, :null], format: "date-time"}
    }
  )

  skip_key_transformation true
end
