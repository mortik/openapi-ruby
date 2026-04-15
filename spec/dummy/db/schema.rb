# frozen_string_literal: true

ActiveRecord::Schema.define(version: 1) do
  create_table :users, force: true do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string :title, null: false
    t.text :body
    t.references :user, null: false, foreign_key: true
    t.timestamps
  end
end
