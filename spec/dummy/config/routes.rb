# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show, :create, :update, :destroy]
      resources :posts, only: [:index, :show, :create, :destroy]
    end
  end

  mount OpenapiRails::Engine => "/api-docs"
end
