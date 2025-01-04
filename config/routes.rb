Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    post "users/login", to: "users#login"
    post "users", to: "users#create"
    get "users/:id", to: "users#show"
  end
end
