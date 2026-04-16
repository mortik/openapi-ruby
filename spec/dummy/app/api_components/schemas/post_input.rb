# frozen_string_literal: true

class Schemas::PostInput
  include OpenapiRuby::Components::Base

  schema(
    type: :object,
    required: %w[title user_id],
    properties: {
      title: {type: :string, minLength: 1},
      body: {type: [:string, :null]},
      user_id: {type: :integer}
    }
  )

  skip_key_transformation true
end
